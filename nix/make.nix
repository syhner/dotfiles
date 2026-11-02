{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./config.nix) username;

  # Every module in modules/: each .nix file and each directory.
  allModules =
    let
      isModule = name: type: type == "directory" || lib.hasSuffix ".nix" name;
      names = lib.attrNames (lib.filterAttrs isModule (builtins.readDir ../modules));
    in
    map (name: import ../modules/${name}) names;

  # Returns both the system and the home. Each of make.system and make.home
  # takes the one it wants, and Nix never evaluates the other.
  build =
    {
      platform,
      hostname ? null, # only the system needs one
      tags ? [ ],
    }:
    let
      # Everything that differs between macOS and Linux.
      darwin = lib.hasSuffix "-darwin" platform;
      systemKey = if darwin then "darwin" else "nixos";
      nixpkgs = if darwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
      makeSystem = if darwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem;
      homeDirectory = if darwin then "/Users/${username}" else "/home/${username}";

      # The modules this build includes.
      included = builtins.filter (module: lib.intersectLists tags module.tags != [ ]) allModules;

      # One part of every included module, as a single list. For example,
      # partOf "unfree" gives every unfree package name.
      partOf = part: builtins.concatMap (module: lib.toList (module.${part} or [ ])) included;

      # nixpkgs for the platform, with nixpkgs-unstable as pkgs.unstable. Both
      # allow the unfree packages the modules name.
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (partOf "unfree");
      importNixpkgs =
        source: overlays:
        import source {
          system = platform;
          inherit config overlays;
        };
      pkgs = importNixpkgs nixpkgs [
        (final: prev: { unstable = importNixpkgs inputs.nixpkgs-unstable [ ]; })
      ];

      # The packages from every module, without any that don't run on this
      # platform.
      packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
        builtins.concatMap (f: f pkgs) (partOf "packages")
      );

      # Extra arguments for every system and home module.
      specialArgs = {
        inherit inputs username;
        repositoryPath = "${homeDirectory}/dotfiles";
      };

      # The home, whether the system manages Home Manager or it runs on its own.
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
    in
    {
      # The system installs the packages and runs Home Manager as part of
      # itself.
      system = makeSystem {
        specialArgs = specialArgs // {
          inherit hostname systemKey;
        };
        modules = [
          ../hosts/${hostname}/configuration.nix
          {
            nixpkgs.pkgs = pkgs;
            environment.systemPackages = packages;
          }
          {
            imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];

            # Home Manager reads the home directory from here.
            users.users.${username}.home = homeDirectory;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs // {
              standalone = false;
            };
            home-manager.users.${username}.imports = homeModules;
          }
        ]
        ++ partOf "system";
      };

      # Home Manager on its own. With no system around, it installs the
      # packages itself.
      home = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgs // {
          standalone = true;
        };
        modules = [ { home.packages = packages; } ] ++ homeModules;
      };
    };
in
{
  system = args: (build args).system;
  home = args: (build args).home;
}
