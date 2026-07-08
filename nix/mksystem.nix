{
  inputs,
  nixpkgs,
  username,
  ...
}:

{
  system,
  hostname ? null,
  # by default, install home manager as a system configuration
  homeManagerStandalone ? false,
  ...
}:

let
  platform =
    {
      x86_64-linux = "nixos";
      aarch64-linux = "nixos";
      x86_64-darwin = "darwin";
      aarch64-darwin = "darwin";
    }
    .${system} or "home";

  mkSystem =
    {
      darwin = inputs.nix-darwin.lib.darwinSystem;
      nixos = nixpkgs.lib.nixosSystem;
      home = inputs.home-manager.lib.homeManagerConfiguration;
    }
    .${platform};
in
mkSystem {
  inherit system;
  specialArgs = {
    inherit
      inputs
      username
      hostname
      platform
      homeManagerStandalone
      ;
  };

  modules = [
    ./modules/configuration/system.nix
    ./modules/darwin/base.nix
    ./modules/homebrew/system.nix
    ./modules/home-manager/system.nix
    ./modules/kanata/system.nix
    ./modules/linearmouse/system.nix
    ./modules/nix/system.nix
    ./modules/nix-index-database/system.nix
    ./modules/nixos/base.nix
    ./modules/nixos/graphical.nix
    ./modules/packages/system.nix
    ./modules/stylix/system.nix
    ./modules/zed/system.nix
  ]
  ++ nixpkgs.lib.optionals homeManagerStandalone [
    ./home.nix
  ];
}
// nixpkgs.lib.optionalAttrs homeManagerStandalone {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = {
    inherit
      inputs
      username
      platform
      homeManagerStandalone
      ;
  };
}
