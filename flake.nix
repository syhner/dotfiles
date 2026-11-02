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

    # theme packages managed by home manager
    stylix.url = "github:danth/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs-nixos";

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

    # secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-nixos";

    # local voice dictation
    hex.url = "github:anomalyco/hex";
    hex.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hex.inputs.home-manager.follows = "home-manager";

    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      make = import ./nix/make.nix { inherit inputs; };
      config = import ./nix/config.nix;
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
            "x86_64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (platform: {
            homeConfigurations.${config.username} = make.home {
              inherit platform;
              tags = [
                "base"
                "workstation"
              ]
              ++ lib.optional (lib.hasSuffix "-darwin" platform) "darwin";
            };
          });

      # homelab

      # darwin
      darwinConfigurations.macbook = make.system {
        platform = "aarch64-darwin";
        hostname = "macbook";
        tags = [
          "base"
          "workstation"
          "darwin"
        ];
      };

      # raspberry-pi

      # usb

      # vm
      nixosConfigurations.vm-utm = make.system {
        platform = "aarch64-linux";
        hostname = "vm-utm";
        tags = [
          "base"
          "workstation"
          "nixos"
          "utm-guest"
        ];
      };

      nixosConfigurations.vm-utm-graphical = make.system {
        platform = "aarch64-linux";
        hostname = "vm-utm-graphical";
        tags = [
          "base"
          "workstation"
          "nixos"
          "utm-guest"
          "graphical"
        ];
      };

      # vps
      nixosConfigurations.vps = make.system {
        platform = "x86_64-linux";
        hostname = "vps";
        tags = [
          "base"
          "nixos"
        ];
      };

      # wsl
    };
}
