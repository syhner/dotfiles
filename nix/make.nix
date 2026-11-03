{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # Every module: each file or directory in modules/. Each is a function of
  # the build's arguments (see moduleArgs), and a build includes the ones whose
  # tags it shares.
  modulePaths = map (name: ../modules/${name}) (builtins.attrNames (builtins.readDir ../modules));

  # What a system and a standalone home both need: the included modules, pkgs,
  # the packages to install and the home.
  build =
    {
      platform, # for example "aarch64-darwin"
      hostname, # null for a standalone home
      tags,
      standalone, # whether Home Manager runs on its own rather than in a system
    }@args:
    let
      # The platform's details, such as platform.isDarwin, platform.isx86_64
      # and platform.system (the "aarch64-darwin" string). Everything that
      # differs by platform checks this.
      platform = lib.systems.elaborate args.platform;

      homeDirectory = if platform.isDarwin then "/Users/${username}" else "/home/${username}";

      # What every module takes. These are plain values rather than module
      # arguments, so a module can branch on any of them, pkgs included,
      # without infinite recursion. Only config still has to come from inside
      # the system or home part.
      moduleArgs = {
        inherit
          homeDirectory
          hostname
          inputs
          lib
          pkgs
          platform
          standalone
          username
          ;
        repositoryPath = "${homeDirectory}/dotfiles";
      };

      # The modules this build includes. tags and unfree must not depend on
      # pkgs, because pkgs needs them first.
      included = builtins.filter (module: lib.intersectLists tags module.tags != [ ]) (
        map (path: import path moduleArgs) modulePaths
      );

      # One part of every included module, as a single list. For example,
      # partOf "unfree" gives every unfree package name.
      partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) included;

      # nixpkgs for the platform, with nixpkgs-unstable as pkgs.unstable. Both
      # allow the unfree packages the modules name.
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (partOf "unfree");
      importNixpkgs =
        source: overlays:
        import source {
          inherit config overlays;
          system = platform.system;
        };
      pkgs = importNixpkgs (if platform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos) [
        (final: prev: {
          unstable = importNixpkgs inputs.nixpkgs-unstable [ ];
        })
      ];
    in
    {
      inherit
        homeDirectory
        partOf
        pkgs
        platform
        ;

      # The packages from every module, without any that don't run on this
      # platform.
      packages = lib.filter (lib.meta.availableOn platform) (partOf "packages");

      # The home, whether the system manages Home Manager or it runs on its own.
      homeModules = [
        {
          home.username = username;
          home.homeDirectory = homeDirectory;

          # The Home Manager release this configuration is compatible with.
          # Read the Home Manager release notes before changing it.
          home.stateVersion = "26.05";

          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;
        }
      ]
      ++ partOf "home";
    };
in
{
  # A system (NixOS or nix-darwin, picked by the platform) that installs the
  # packages and runs Home Manager as part of itself.
  system =
    {
      platform,
      hostname,
      tags,
    }:
    let
      shared = build {
        inherit platform hostname tags;
        standalone = false;
      };
    in
    (if shared.platform.isDarwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem) {
      # For the host's own configuration.nix, which isn't a module.
      specialArgs = { inherit inputs hostname username; };
      modules = [
        ../hosts/${hostname}/configuration.nix
        {
          nixpkgs.pkgs = shared.pkgs;
          environment.systemPackages = shared.packages;
        }
        {
          imports = [
            inputs.home-manager.${
              if shared.platform.isDarwin then "darwinModules" else "nixosModules"
            }.home-manager
          ];

          # Home Manager reads the home directory from here.
          users.users.${username}.home = shared.homeDirectory;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username}.imports = shared.homeModules;
        }
      ]
      ++ shared.partOf "system";
    };

  # Home Manager on its own. With no system around, it installs the packages
  # itself.
  home =
    { platform, tags }:
    let
      shared = build {
        inherit platform tags;
        hostname = null;
        standalone = true;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = shared.pkgs;
      modules = [ { home.packages = shared.packages; } ] ++ shared.homeModules;
    };
}
