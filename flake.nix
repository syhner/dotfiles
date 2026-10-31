{
  description = "NixOS, nix-darwin, and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
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
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    # manage homebrew packages
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # find packages with a certain file (e.g. nix-locate bin/rg)
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # declarative disk partitioning and formatting
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      ...
    }:
    let
      mkSystem = import ./mkSystem.nix { inherit inputs; };
      username = import ./config/username.nix;
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # anywhere
      # nixosConfigurations.anywhere = nixpkgs.lib.nixosSystem {
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
      legacyPackages = forAllSystems (system: {
        homeConfigurations.${username} = mkSystem {
          inherit system;
          type = "home-manager";
        };
      });

      # homelab

      # darwin
      darwinConfigurations.macbook = mkSystem {
        system = "aarch64-darwin";
        hostname = "macbook";
        extraModules = [
          inputs.sops-nix.darwinModules.sops
          ./modules/sops/system.nix
        ];
      };

      # raspberry-pi

      # usb

      # vm
      nixosConfigurations.vm-utm = mkSystem {
        system = "aarch64-linux";
        hostname = "vm-utm";
        cfg.nixos.share = true;
      };

      nixosConfigurations.vm-utm-graphical = mkSystem {
        system = "aarch64-linux";
        hostname = "vm-utm-graphical";
        cfg = {
          nixos.share = true;
          nixos.graphical = true;
        };
      };

      # vps
      nixosConfigurations.vps = mkSystem {
        system = "x86_64-linux";
        hostname = "vps";
        cfg = {
          nixos.avahi = false;
          nix-index-database = false;
          nixos.ssh = false;
          nixos.systemd-boot = false;
          package.proton-vpn = false;
          package.obsidian = false;
          package.spotify = false;
          package.opencode = false;
          package.nil = false;
          package.nixd = false;
          package.nerd-fonts = false;
        };
      };

      # wsl
    };
}
