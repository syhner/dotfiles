{
  description = "NixOS, nix-darwin, and Home Manager configurations";

  inputs = {
    nixpkgs-nixos.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-fd40cef8d.url = "github:nixos/nixpkgs/fd40cef8d797670e203a27a91e4b8e6decf0b90c";

    # manage user environment
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # manage macOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    # manage homebrew packages
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # find packages with a certain file (e.g. nix-locate bin/rg)
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # declarative disk partitioning and formatting
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # local voice dictation
    hex.url = "github:anomalyco/hex";
    hex.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hex.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    inputs:
    let
      make = import ./nix/make.nix { inherit inputs; };
      settings = import ./nix/settings.nix;
      inherit (inputs.nixpkgs-nixos) lib;
    in
    {
      # anywhere
      # nixosConfigurations.anywhere = inputs.nixpkgs-nixos.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     inputs.disko.nixosModules.disko
      #     ./hosts/anywhere/configuration.nix
      #     ./hosts/anywhere/hardware-configuration.nix
      #   ];
      # };

      # desktop
      nixosConfigurations.desktop = make {
        platform = "x86_64-linux";
        hostname = "desktop";
        allowUnfree = true;
        tags = [
          "base"
          "dev"
          "gui"
          "nixos"
          "plasma"
          "nvidia"
        ];
      };

      # dev (remote development server)

      # home-manager standalone
      legacyPackages =
        lib.genAttrs
          [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (system: {
            homeConfigurations.${settings.username} = make {
              platform = system;
              standalone = true;
              allowUnfree = true;
              tags = [
                "base"
                "dev"
                "gui"
              ]
              ++ lib.optional (lib.hasSuffix "-darwin" system) "darwin";
            };
          });

      # homelab
      nixosConfigurations.homelab = make {
        platform = "x86_64-linux";
        hostname = "homelab";
        tags = [
          "base"
          "nixos"
        ];
        # At home and always on, so its cache is asked first of the fleet's.
        # Until publicKey is set, no machine downloads from it.
        substituter = {
          publicKey = null;
          priority = 50;
        };
        builder = {
          maxJobs = 3;
          speedFactor = 2;
        };
      };

      # darwin
      darwinConfigurations.macbook = make {
        platform = "aarch64-darwin";
        hostname = "macbook";
        allowUnfree = true;
        tags = [
          "base"
          "dev"
          "gui"
          "darwin"
          "linux-builder"
        ];
      };

      # A Mac mini that stays on at home, so the other machines can build for
      # macOS on it.
      darwinConfigurations.macmini = make {
        platform = "aarch64-darwin";
        hostname = "macmini";
        tags = [
          "base"
          "darwin"
        ];
        # Sized for the M6 model (12 cores). An M5 Pro (15 or 18) could take
        # more builds, and a higher speedFactor.
        builder = {
          maxJobs = 3;
          speedFactor = 3;
        };
        # Until publicKey is set, no machine downloads from it.
        substituter = {
          publicKey = null;
          priority = 51;
        };
      };

      # raspberry-pi

      # usb

      # vm
      nixosConfigurations.utm-guest = make {
        platform = "aarch64-linux";
        hostname = "utm-guest";
        allowUnfree = true;
        tags = [
          "base"
          "dev"
          "nixos"
          "utm-guest"
        ];
      };

      nixosConfigurations.utm-guest-gnome = make {
        platform = "aarch64-linux";
        hostname = "utm-guest-gnome";
        allowUnfree = true;
        tags = [
          "base"
          "dev"
          "gui"
          "nixos"
          "utm-guest"
          "gnome"
        ];
      };

      # vps
      nixosConfigurations.vps = make {
        platform = "x86_64-linux";
        hostname = "vps";
        tags = [
          "base"
          "nixos"
          "exit-node"
        ];
        # An OVH Rise-S dedicated server: a Ryzen 7 9700X (8 cores, 16 threads)
        # with 64 GB. Faster per core than the homelab, but away from home, so
        # what a build needs that isn't in a cache is uploaded over the
        # internet.
        builder = {
          maxJobs = 3;
          speedFactor = 3;
        };
        # Away from home, so its cache is asked last of the fleet's. Until
        # publicKey is set, no machine downloads from it.
        substituter = {
          publicKey = null;
          priority = 52;
        };
      };

      # wsl

      # What CI evaluates and builds, and where it pushes to, read by
      # .github/workflows/ci.yml so that it lists none of it itself. CI's plan
      # job runs `nix eval --json .#ci`, which prints this as JSON:
      #
      #   {
      #     "cache": "syhner",
      #     "configurations": [
      #       { "attr": "darwinConfigurations.macbook.system", "system": "aarch64-darwin" },
      #       ...
      #     ],
      #     "unfree": "(claude-code|discord|...)"
      #   }
      ci =
        let
          inherit (inputs) self;

          # One entry for each configuration in an output, for example
          # entries "nixosConfigurations" "config.system.build.toplevel"
          # self.nixosConfigurations gives, for the vps:
          #
          #   {
          #     attr = "nixosConfigurations.vps.config.system.build.toplevel";
          #     system = "x86_64-linux";
          #     unfree = [ ];
          #   }
          #
          # attr is what CI builds: the same thing nixos-rebuild, darwin-rebuild
          # or home-manager would. system is the platform it builds on, and
          # unfree the unfree packages it may use. Both come from make.nix,
          # which keeps them in each configuration's dotfiles attribute.
          entries =
            prefix: build:
            lib.mapAttrsToList (
              name: configuration: {
                attr = "${prefix}.${name}.${build}";
                system = configuration.dotfiles.platform;
                inherit (configuration.dotfiles) unfree;
              }
            );

          # Every configuration: the systems, then the standalone homes, which
          # are under legacyPackages.<platform>.
          configurations =
            entries "darwinConfigurations" "system" self.darwinConfigurations
            ++ entries "nixosConfigurations" "config.system.build.toplevel" self.nixosConfigurations
            ++ lib.concatMap (
              system:
              entries "legacyPackages.${system}.homeConfigurations" "activationPackage"
                self.legacyPackages.${system}.homeConfigurations
            ) (builtins.attrNames self.legacyPackages);
        in
        {
          # The Cachix cache to push to.
          cache = settings.cache.name;

          # What to evaluate and build, without the unfree lists, which CI
          # only needs all together.
          configurations = map (configuration: {
            inherit (configuration) attr system;
          }) configurations;

          # A regex matching every unfree package any configuration uses, and
          # the downloads and parts they're made from, which have the
          # package's name in theirs. CI never builds or pushes what matches.
          unfree = "(${
            lib.concatMapStringsSep "|" lib.escapeRegex (
              lib.unique (lib.concatMap (configuration: configuration.unfree) configurations)
            )
          })";
        };
    };
}
