{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  settings = import ./settings.nix;

  makeCommon =
    {
      platform,
      tags,
      allowUnfree,
      machineDetails,
    }@args:
    let
      platform = lib.systems.elaborate args.platform;

      nixpkgsArgs = {
        system = platform.system;
        # only allow unfree packages from included features. pkgs is made
        # before the features are called (they take it), so a feature's tags
        # and unfree list mustn't use an unfree package, or this depends on itself
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
      machine = machineDetails // {
        inherit platform tags;
      };

      # allow a feature to reference every other machine
      otherMachines = builtins.filter (other: machine.standalone || other.hostname != machine.hostname) (
        map (configuration: configuration.machine) (
          builtins.attrValues (inputs.self.nixosConfigurations // inputs.self.darwinConfigurations)
        )
      );

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

      # every feature called with what it takes
      features = map (name: import ../features/${name} featureArgs) (
        builtins.attrNames (builtins.readDir ../features)
      );

      # features included due to tags
      includedFeatures = builtins.filter (feature: lib.intersectLists tags feature.tags != [ ]) features;

      # what the included features give e.g. included.packages is every package they install
      included = lib.genAttrs [ "packages" "home" "system" "unfree" ] (
        name: builtins.concatMap (feature: lib.toList (feature.${name} or [ ])) includedFeatures
      );
    in
    {
      inherit homeDirectory machine pkgs;

      # The packages to install, without any that don't run on this platform.
      packages = builtins.filter (lib.meta.availableOn platform) included.packages;

      # The included features' system parts.
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

      finish =
        configuration:
        configuration
        // {
          # make machine configs (this one, and others) available to features
          machine = machine // {
            # for .github/ci.nix
            unfreePackageNames = included.unfree;
          };
        };
    };
in
{
  # A NixOS or nix-darwin system, which runs Home Manager itself.
  makeSystem =
    {
      platform,
      hostname,
      tags ? [ ],
      allowUnfree ? false,
      builder ? null,
      buildOwnPlatform ? false,
      substituter ? null,
    }:
    let
      common = makeCommon {
        inherit platform tags allowUnfree;
        machineDetails = {
          inherit
            buildOwnPlatform
            builder
            hostname
            substituter
            ;
          standalone = false;
          address = "${hostname}.${settings.tailnet}";
          servesFleet = builder != null || substituter != null;
        };
      };
      inherit (common.machine.platform) isDarwin isLinux;
    in
    common.finish (
      (if isDarwin then inputs.nix-darwin.lib.darwinSystem else lib.nixosSystem) {
        # for machines/<hostname>/configuration.nix
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
    );

  # standalone home manager configuration that runs on its own rather than in a system.
  makeHome =
    {
      platform,
      tags ? [ ],
      allowUnfree ? false,
    }:
    let
      common = makeCommon {
        inherit platform tags allowUnfree;
        machineDetails.standalone = true;
      };
    in
    common.finish (
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit (common) pkgs;
        # With no system around, it installs the packages itself.
        modules = [ { home.packages = common.packages; } ] ++ common.homeModules;
      }
    );
}
