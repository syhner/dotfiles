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
      configuration = { ... }: {

      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#smacbook
      darwinConfigurations."smacbook" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit self inputs; };
        modules = [
          configuration
          ./modules/common.nix
          ./modules/darwin.nix
          ./modules/homebrew.nix
          ./modules/kanata.nix
          ./modules/packages.nix
          nix-homebrew.darwinModules.nix-homebrew
          nix-index-database.darwinModules.nix-index
          {
            nixpkgs.hostPlatform = "aarch64-darwin";
            networking.hostName = "smacbook";
            networking.computerName = "smacbook";
            system.primaryUser = "siraj";

            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "siraj";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };

            nixpkgs.overlays = [
              (final: prev: {
                kanata = prev.kanata.overrideAttrs (old: {
                  cargoBuildFeatures = (old.cargoBuildFeatures or [ ]) ++ [ "cmd" ];
                });
              })
            ];
          }
        ];
      };
    };
}
