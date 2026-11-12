{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  settings = import ./settings.nix;

  # every system's machine, for otherMachines and .github/ci.nix
  machines = map (configuration: configuration.machine) (
    builtins.attrValues (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations)
  );

  # shared by a system and a standalone home (which has no hostname)
  makeCommon =
    {
      platform,
      hostname ? null,
      features ? { },
      allowUnfree ? false,
    }@args:
    let
      platform = lib.systems.elaborate args.platform;

      nixpkgsArgs = {
        system = platform.system;
        # only allow unfree packages from enabled features. pkgs is made
        # before the features are evaluated (they take it), so what enables a
        # feature, and its unfree list, mustn't use an unfree package, or this
        # depends on itself
        config.allowUnfreePredicate =
          package: allowUnfree && builtins.elem (lib.getName package) included.unfree;
      };

      pkgs = import (
        if platform.isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos
      ) nixpkgsArgs;
      unstable = import inputs.nixpkgs-unstable nixpkgsArgs;

      homeDirectory =
        if platform.isDarwin then "/Users/${settings.username}" else "/home/${settings.username}";
      repositoryPath = "${homeDirectory}/${settings.checkout}";

      # feature symlink creator with relative path
      symlinkToCheckout =
        path:
        let
          name = inputs.home-manager.lib.hm.strings.storeFileName (baseNameOf path);
          target = repositoryPath + lib.removePrefix (toString ../.) (toString path);
        in
        # Fail evaluation, not the machine, when the file is missing (or not
        # tracked by git, which leaves it out of the flake's source).
        assert lib.assertMsg (builtins.pathExists path) "symlinkToCheckout: ${target} doesn't exist";
        pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg target} $out";

      # allow a feature to reference the machine being built
      machine = {
        inherit platform hostname;
        standalone = hostname == null;
        # where the others reach it, which only machines on the tailnet resolve
        address = "${hostname}.${settings.tailnet}";
        # its features' settings, for the other machines
        inherit (included) features;
        # for .github/ci.nix
        unfreePackageNames = included.unfree;
      };

      # allow a feature to reference every other machine (all of them, for a standalone home)
      otherMachines = builtins.filter (other: other.hostname != hostname) machines;

      featureArgs = {
        inherit
          homeDirectory
          inputs
          lib
          machine
          otherMachines
          pkgs
          repositoryPath
          settings
          symlinkToCheckout
          unstable
          ;
      };

      # what the enabled features give e.g. included.packages is every package they install
      included =
        (lib.evalModules {
          class = "features";
          specialArgs = featureArgs;
          modules = [
            ./features.nix
            {
              _file = "flake.nix, ${if hostname == null then "the standalone home" else hostname}";
              inherit features;
            }
          ];
        }).config;
    in
    {
      inherit homeDirectory machine pkgs;

      # The packages to install, without any that don't run on this platform.
      packages = builtins.filter (lib.meta.availableOn platform) included.packages;

      # The enabled features' system parts.
      systemModules = included.system;

      # The home, whether a system runs it or it runs on its own.
      homeModules = [
        {
          home.username = settings.username;
          home.homeDirectory = homeDirectory;
          home.stateVersion = "26.05";
          programs.home-manager.enable = true;
        }
      ]
      ++ included.home;
    };
in
{
  inherit machines;

  # A NixOS or nix-darwin system, which runs Home Manager itself.
  makeSystem =
    { hostname, ... }@args:
    let
      common = makeCommon args;
      inherit (common.machine.platform) isDarwin isLinux;
    in
    (if isDarwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem) {
      specialArgs = { inherit inputs settings; };
      modules = [
        ../machines/${hostname}/configuration.nix
        {
          nixpkgs.pkgs = common.pkgs;
          environment.systemPackages = common.packages;
        }
        {
          imports = [
            inputs.home-manager.${if isDarwin then "darwinModules" else "nixosModules"}.home-manager
          ];

          users.users.${settings.username}.home = common.homeDirectory;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${settings.username}.imports = common.homeModules;
        }
      ]
      # for integrated home-manager
      ++ lib.optional isLinux {
        users.users.${settings.username}.isNormalUser = true;
      }
      ++ common.systemModules;
    }
    # for otherMachines, and .github/ci.nix
    // {
      inherit (common) machine;
    };

  # standalone home manager configuration that runs on its own rather than in a system.
  makeHome =
    args:
    let
      common = makeCommon args;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit (common) pkgs;
      # With no system around, it installs the packages itself.
      modules = [ { home.packages = common.packages; } ] ++ common.homeModules;
    }
    // {
      inherit (common) machine;
    };
}
