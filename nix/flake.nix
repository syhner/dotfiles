{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # nix-locate bin/rg - find packages with a bin/rg file
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      nix-index-database,
    }:
    let
      username = "siraj";
      hostnames = {
        nixosVM = "sutf";
        darwin = "smacbook";
      };
    in
    {
      nixosConfigurations.${hostnames.nixosVM} = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit username hostnames; };
        modules = [
          ./hosts/nixos-vm/configuration.nix
          ./modules/common/nix.nix
          ./modules/common/packages.nix
          ./modules/common/shell-zsh.nix
          ./modules/nixos/base.nix
          ./modules/nixos/graphical.nix
        ];
      };

      darwinConfigurations.${hostnames.darwin} = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            self
            inputs
            username
            hostnames
            ;
        };
        modules = [
          ./hosts/macbook/configuration.nix
          ./modules/common/nix.nix
          ./modules/common/packages.nix
          ./modules/common/shell-zsh.nix
          ./modules/macos/base.nix
          ./modules/macos/homebrew.nix
          ./modules/macos/kanata.nix
          nix-homebrew.darwinModules.nix-homebrew
          nix-index-database.darwinModules.nix-index
        ];
      };
    };
}
