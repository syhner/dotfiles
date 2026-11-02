{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # Every module in modules/, in the order of their names, and the ones that
  # have any of the given tags.
  isModule = name: type: type == "directory" || lib.hasSuffix ".nix" name;
  allModules = map (name: lib.toFunction (import ../modules/${name}) { }) (
    lib.attrNames (lib.filterAttrs isModule (builtins.readDir ../modules))
  );
  tagged =
    tags: builtins.filter (module: lib.any (tag: builtins.elem tag tags) module.tags) allModules;

  isDarwin = lib.hasSuffix "-darwin";

  # What systems and homes build from, given the platform, the tags of the
  # modules and the modules on top.
  common = platform: tags: extraModules: rec {
    modules = tagged tags ++ extraModules;

    # A part of every module: the tagged ones, then the ones on top.
    partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) modules;

    darwin = isDarwin platform;

    # The nixpkgs for the platform, with unstable packages under pkgs.unstable.
    # Both allow the unfree packages the modules name.
    pkgs =
      let
        unfree = partOf "unfree";
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfree;
      in
      import (if darwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos) {
        system = platform;
        inherit config;
        overlays = [
          (final: prev: {
            unstable = import inputs.nixpkgs-unstable {
              system = platform;
              inherit config;
            };
          })
        ];
      };

    # The packages the modules list, skipping any not available on the
    # platform. They install system-wide, or through Home Manager when it runs
    # standalone.
    packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
      builtins.concatMap (f: f pkgs) (partOf "packages")
    );

    homeDirectory = if darwin then "/Users/${username}" else "/home/${username}";
    specialArgs = {
      inherit inputs username;
      repositoryPath = "${homeDirectory}/dotfiles";
    };

    # Every home, integrated or standalone.
    homeModules = [
      {
        home.username = username;
        home.homeDirectory = homeDirectory;

        # The Home Manager release this configuration is compatible with. Read
        # the Home Manager release notes before changing it.
        home.stateVersion = "26.05";

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
      }
    ]
    ++ partOf "home";
  };
in
{
  inherit isDarwin;

  system =
    {
      platform,
      hostname,
      tags ? [ ],
      modules ? [ ],
    }:
    let
      c = common platform tags modules;
      systemKey = if c.darwin then "darwin" else "nixos";
      build = if c.darwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem;
    in
    build {
      specialArgs = c.specialArgs // {
        inherit hostname systemKey;
      };
      modules = [
        ../hosts/${hostname}/configuration.nix
        {
          nixpkgs.pkgs = c.pkgs;
          environment.systemPackages = c.packages;
        }
        {
          imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
          # Home Manager reads the home directory from here.
          users.users.${username}.home = c.homeDirectory;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = c.specialArgs // {
            standalone = false;
          };
          home-manager.users.${username}.imports = c.homeModules;
        }
      ]
      ++ c.partOf "system";
    };

  home =
    {
      platform,
      tags ? [ ],
      modules ? [ ],
    }:
    let
      c = common platform tags modules;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit (c) pkgs;
      extraSpecialArgs = c.specialArgs // {
        standalone = true;
      };
      modules = [ { home.packages = c.packages; } ] ++ c.homeModules;
    };
}
