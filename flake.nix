{
  description = "NixOS, nix-darwin, and Home Manager configurations";

  inputs = {
    nixpkgs-nixos.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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

    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      inherit (import ./nix { inherit inputs; })
        mkSystem
        mkHome
        isDarwin
        ;
      moduleSets = import ./nix/module-sets.nix;
      inherit (import ./nix/config.nix) username;
      lib = inputs.nixpkgs-nixos.lib;
      forAllPlatforms = lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
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
      legacyPackages = forAllPlatforms (platform: {
        homeConfigurations.${username} = mkHome {
          inherit platform;
          modules =
            moduleSets.base ++ moduleSets.workstation ++ lib.optionals (isDarwin platform) moduleSets.darwin;
        };
      });

      # homelab

      # darwin
      darwinConfigurations.macbook = mkSystem {
        platform = "aarch64-darwin";
        hostname = "macbook";
        modules = moduleSets.base ++ moduleSets.workstation ++ moduleSets.darwin;
      };

      # raspberry-pi

      # usb

      # vm
      nixosConfigurations.vm-utm = mkSystem {
        platform = "aarch64-linux";
        hostname = "vm-utm";
        modules = moduleSets.base ++ moduleSets.workstation ++ moduleSets.vm-utm;
      };

      nixosConfigurations.vm-utm-graphical = mkSystem {
        platform = "aarch64-linux";
        hostname = "vm-utm-graphical";
        modules = moduleSets.base ++ moduleSets.workstation ++ moduleSets.vm-utm ++ [ "graphical" ];
      };

      # vps
      nixosConfigurations.vps = mkSystem {
        platform = "x86_64-linux";
        hostname = "vps";
        modules = moduleSets.base ++ [
          "nixos-base"
          "tailscale"
        ];
      };

      # wsl
    };
}
