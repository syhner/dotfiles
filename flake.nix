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
        ];
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
      };

      # wsl
    };
}
