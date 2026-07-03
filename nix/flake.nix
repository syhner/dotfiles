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

      common-modules = platform: [
        ./modules/common/nix.nix
        ./modules/common/packages.nix
        ./modules/common/shell-zsh.nix
        inputs.nix-index-database."${platform}Modules".nix-index
      ];

      home-manager-config = platform: [
        inputs.home-manager."${platform}Modules".home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs username; };
          home-manager.users.${username} = ./modules/home;
        }
      ];

      home-modules = platform: [
        inputs.stylix."${platform}Modules".stylix
        ./modules/home/stylix.nix
      ];

      nixosModules = [
        ./modules/nixos/base.nix
        ./modules/nixos/graphical.nix
      ];

      darwinModules = [
        ./modules/macos/base.nix
        ./modules/macos/homebrew.nix
        ./modules/macos/kanata.nix
      ];

      platformModules =
        platform:
        if platform == "nixos" then
          nixosModules
        else if platform == "darwin" then
          darwinModules
        else
          throw "Unknown platform: ${platform}";

      mkArgs = hostname: { inherit inputs username hostname; };
    in
    {
      # desktop

      # dev (remote development server)

      # home-manager standalone
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = { inherit inputs username; };
        modules = home-modules "home" ++ [
          ./modules/home
        ];
      };

      # homelab

      darwinConfigurations.smacbook = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = mkArgs "smacbook";
        modules =
          common-modules "darwin"
          ++ home-manager-config "darwin"
          ++ home-modules "darwin"
          ++ platformModules "darwin"
          ++ [
            ./hosts/macbook/configuration.nix
            inputs.nix-homebrew.darwinModules.nix-homebrew
          ];
      };

      # raspberry-pi

      # usb

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = mkArgs "vm";
        modules =
          common-modules "nixos"
          ++ home-manager-config "nixos"
          ++ home-modules "nixos"
          ++ platformModules "nixos"
          ++ [
            ./hosts/vm/configuration.nix
          ];
      };

      nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = mkArgs "vps";
        modules =
          common-modules "nixos"
          ++ home-manager-config "nixos"
          ++ home-modules "nixos"
          # ++ platformModules "nixos"
          ++ [
            ./hosts/vps/configuration.nix
            ./hosts/vps/hardware-configuration.nix
            inputs.disko.nixosModules.disko
          ];
      };

      # wsl

      # anywhere (install nixos over ssh)
      /*
        nix run nixpkgs#nixos-anywhere -- \
          --flake .#anywhere \
          --generate-hardware-config nixos-generate-config ./hosts/anywhere/hardware-configuration.nix
          --kexec-extra-flags "--kexec-syscall" \
          --target-host root@<hostname>

        # then the configuration can be updated with
        nixos-rebuild switch --flake .#<name> --target-host root@<hostname>
      */
      nixosConfigurations.anywhere = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.disko.nixosModules.disko
          ./hosts/anywhere/configuration.nix
          ./hosts/anywhere/hardware-configuration.nix
        ];
      };
    };
}
