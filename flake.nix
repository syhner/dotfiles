{
  description = "nix-darwin system flake";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin" ?
    # nixpkgs.url = "github:nixos/nixpkgs/release-26.05" ?
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-fd40cef8d.url = "github:nixos/nixpkgs/fd40cef8d797670e203a27a91e4b8e6decf0b90c";

    # manage user environment
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # theme packages managed by home manager
    stylix.url = "github:danth/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # manage macOS
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # manage homebrew packages
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # find packages with a certain file (e.g. nix-locate bin/rg)
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # declarative disk partitioning and formatting
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      username = "siraj";
      mkSystem = import ./mkSystem.nix {
        inherit
          inputs
          nixpkgs
          username
          ;
      };
    in
    {
      # anywhere
      nixosConfigurations.anywhere = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.disko.nixosModules.disko
          ./hosts/anywhere/configuration.nix
          ./hosts/anywhere/hardware-configuration.nix
        ];
      };

      # desktop

      # dev (remote development server)

      # home-manager standalone
      homeConfigurations.${username} = mkSystem {
        system = "aarch64-darwin";
        type = "home-manager";
      };

      # homelab

      # darwin
      darwinConfigurations.macbook = mkSystem {
        system = "aarch64-darwin";
        hostname = "macbook";
      };

      # raspberry-pi

      # usb

      # vm
      nixosConfigurations.vm = mkSystem {
        system = "aarch64-linux";
        hostname = "vm";
      };

      # vps

      # wsl
    };
}
