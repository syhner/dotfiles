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

    # NixOS on Windows, in WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-26.05";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # local voice dictation
    hex.url = "github:anomalyco/hex";
    hex.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hex.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    inputs:
    let
      inherit (import ./nix/make.nix { inherit inputs; }) makeSystem makeHome;
      settings = import ./nix/settings.nix;
      lib = inputs.nixpkgs-nixos.lib;
      self = inputs.self;
    in
    {
      # home-manager standalone
      legacyPackages =
        lib.genAttrs
          [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (platform: {
            homeConfigurations.${settings.username} = makeHome {
              inherit platform;
              allowUnfree = true;
              tags = [
                "base"
                "dev"
                "gui"
              ]
              ++ lib.optional (lib.hasSuffix "-darwin" platform) "darwin";
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
        buildOwnPlatform = true;
        tags = [
          "base"
          "dev"
          "gui"
          "nixos"
          "plasma"
          "nvidia"
        ];
      };

      nixosConfigurations.homelab = makeSystem {
        platform = "x86_64-linux";
        hostname = "homelab";
        tags = [
          "base"
          "nixos"
        ];
        substituter.priority = 50;
        builder = {
          maxJobs = 3;
          speedFactor = 2;
        };
      };

      darwinConfigurations.macbook = makeSystem {
        platform = "aarch64-darwin";
        hostname = "macbook";
        allowUnfree = true;
        buildOwnPlatform = true;
        tags = [
          "base"
          "dev"
          "gui"
          "darwin"
        ];
      };

      darwinConfigurations.macmini = makeSystem {
        platform = "aarch64-darwin";
        hostname = "macmini";
        tags = [
          "base"
          "darwin"
          "linux-builder"
        ];
        builder = {
          maxJobs = 3;
          speedFactor = 3;
        };
        substituter.priority = 51;
      };

      nixosConfigurations.utm-guest = makeSystem {
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

      nixosConfigurations.utm-guest-gnome = makeSystem {
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

      nixosConfigurations.vps = makeSystem {
        platform = "x86_64-linux";
        hostname = "vps";
        tags = [
          "base"
          "nixos"
          "exit-node"
        ];
      };

      nixosConfigurations.wsl = makeSystem {
        platform = "x86_64-linux";
        hostname = "wsl";
        allowUnfree = true;
        tags = [
          "base"
          "dev"
          "nixos"
          "wsl"
        ];
      };

      ci = import ./.github/ci.nix { inherit lib self settings; };
    };
}
