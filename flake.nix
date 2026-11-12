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

    # find packages with a certain file (e.g. nix-locate bin/rg)
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # declarative disk partitioning and formatting
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # secrets, decrypted on activation (see features/secrets.nix)
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # NixOS on Windows, in WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-26.05";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # manage macOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    # manage homebrew packages
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Homebrew's taps, pinned like the other inputs, so what it installs only
    # changes when flake.lock does (see features/darwin/homebrew.nix)
    homebrew-core.url = "github:homebrew/homebrew-core";
    homebrew-core.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-cask.flake = false;
    # for features/hex
    hex-tap.url = "github:anomalyco/homebrew-tap";
    hex-tap.flake = false;
    # for features/deskflow
    deskflow-tap.url = "github:deskflow/homebrew-tap";
    deskflow-tap.flake = false;

    # local voice dictation
    hex.url = "github:anomalyco/hex";
    hex.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hex.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    inputs:
    let
      inherit (import ./nix/make.nix { inherit inputs; }) makeSystem makeHome machines;
      settings = import ./nix/settings.nix;
      lib = inputs.nixpkgs-nixos.lib;
      self = inputs.self;
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      pkgsFor = platform: inputs.nixpkgs-nixos.legacyPackages.${platform};

      # .sops.yaml, from nix/sops.nix
      sopsConfig =
        platform:
        (pkgsFor platform).writeText ".sops.yaml" (
          import ./nix/sops.nix { inherit lib machines settings; }
        );
    in
    {
      # home-manager standalone
      legacyPackages = lib.genAttrs platforms (platform: {
        homeConfigurations.${settings.username} = makeHome {
          inherit platform;
          allowUnfree = true;
          features = {
            profiles.base.enable = true;
            profiles.dev.enable = true;
            profiles.gui.enable = true;
            profiles.darwin.enable = lib.hasSuffix "-darwin" platform;
          };
        };
      });

      nixosConfigurations.anywhere = makeSystem {
        platform = "x86_64-linux";
        hostname = "anywhere";
      };

      nixosConfigurations.desktop = makeSystem {
        platform = "x86_64-linux";
        hostname = "desktop";
        allowUnfree = true;
        features = {
          profiles.base.enable = true;
          profiles.dev.enable = true;
          profiles.gui.enable = true;
          profiles.nixos.enable = true;
          fleet-builders.buildOwnPlatform = true;
          plasma.enable = true;
          nvidia.enable = true;
        };
      };

      nixosConfigurations.homelab = makeSystem {
        platform = "x86_64-linux";
        hostname = "homelab";
        features = {
          profiles.base.enable = true;
          profiles.nixos.enable = true;
          fleet-builders.builder = {
            maxJobs = 3;
            speedFactor = 2;
          };
          fleet-substituters = {
            priority = 50;
            publicKey = "homelab-1:PfMJ7JMIMXGLL2ebAmpLWVvq/kMza3tRuvV/hyggwzA=";
          };
        };
      };

      darwinConfigurations.macbook = makeSystem {
        platform = "aarch64-darwin";
        hostname = "macbook";
        allowUnfree = true;
        features = {
          profiles.base.enable = true;
          profiles.dev.enable = true;
          profiles.gui.enable = true;
          profiles.darwin.enable = true;
          fleet-builders.buildOwnPlatform = true;
        };
      };

      darwinConfigurations.macmini = makeSystem {
        platform = "aarch64-darwin";
        hostname = "macmini";
        features = {
          profiles.base.enable = true;
          profiles.darwin.enable = true;
          fleet-builders = {
            builder = {
              maxJobs = 3;
              speedFactor = 3;
            };
            # Builds macOS itself, rather than on any slower Mac builder.
            buildOwnPlatform = true;
            linuxVM = true;
          };
          fleet-substituters = {
            priority = 51;
            publicKey = "macmini-1:GAdbocn1Zd4m1QwwTA1i5y6sE1qA2oSPhQyZRrWCb0A=";
          };
        };
      };

      nixosConfigurations.utm-guest = makeSystem {
        platform = "aarch64-linux";
        hostname = "utm-guest";
        allowUnfree = true;
        features = {
          profiles.base.enable = true;
          profiles.dev.enable = true;
          profiles.nixos.enable = true;
          utm-guest.enable = true;
        };
      };

      nixosConfigurations.utm-guest-gnome = makeSystem {
        platform = "aarch64-linux";
        hostname = "utm-guest-gnome";
        allowUnfree = true;
        features = {
          profiles.base.enable = true;
          profiles.dev.enable = true;
          profiles.gui.enable = true;
          profiles.nixos.enable = true;
          utm-guest.enable = true;
          gnome.enable = true;
        };
      };

      nixosConfigurations.vps = makeSystem {
        platform = "x86_64-linux";
        hostname = "vps";
        features = {
          profiles.base.enable = true;
          profiles.nixos.enable = true;
          tailscale.exitNode = true;
        };
      };

      nixosConfigurations.wsl = makeSystem {
        platform = "x86_64-linux";
        hostname = "wsl";
        allowUnfree = true;
        features = {
          profiles.base.enable = true;
          profiles.dev.enable = true;
          profiles.nixos.enable = true;
          wsl.enable = true;
        };
      };

      checks = lib.genAttrs platforms (
        platform:
        import ./nix/checks.nix {
          pkgs = pkgsFor platform;
          formatter = self.formatter.${platform};
          sopsConfig = sopsConfig platform;
          src = self;
        }
      );

      formatter = lib.genAttrs platforms (platform: (pkgsFor platform).nixfmt-tree);

      packages = lib.genAttrs platforms (platform: {
        sops-config = sopsConfig platform;
      });

      ci = import ./.github/ci.nix {
        inherit
          lib
          machines
          self
          settings
          ;
      };
    };
}
