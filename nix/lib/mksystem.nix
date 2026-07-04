{
  inputs,
  nixpkgs,
  username,
  ...
}:

{
  system,
  hostname ? null,
  enableNixosModules ? true,
  enableDarwinModules ? true,
  enableSystemModules ? true,
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
    .${system} or "home"; # home-manager standalone

  isNixOS = platform == "nixos";
  isDarwin = platform == "darwin";
  isSystem = platform == "nixos" || platform == "darwin";
  isHomeManagerStandalone = platform == "home";

  mkSystem =
    {
      darwin = inputs.nix-darwin.lib.darwinSystem;
      nixos = nixpkgs.lib.nixosSystem;
      home = inputs.home-manager.lib.homeManagerConfiguration;
    }
    .${platform} or (throw "Unknown platform: ${platform}");

  inherit (nixpkgs.lib) optionals optionalAttrs;

in
mkSystem {
  inherit system;
  specialArgs = {
    inherit
      inputs
      username
      hostname
      platform
      ;
  };

  modules = [
    ../modules/home/nix-index-database.nix
    ../modules/home/stylix.nix
  ]
  ++ optionals isSystem [
    ../hosts/${hostname}/configuration.nix
  ]
  ++ optionals (isSystem && enableSystemModules) [
    inputs.home-manager."${platform}Modules".home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs username; };
      home-manager.users.${username} = ../modules/home;
    }
    ../modules/common/base.nix
    ../modules/common/nix.nix
    ../modules/common/packages.nix
  ]
  ++ optionals (isNixOS && enableNixosModules) [
    ../modules/nixos/base.nix
    ../modules/nixos/graphical.nix
  ]
  ++ optionals (isDarwin && enableDarwinModules) [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ../modules/macos/base.nix
    ../modules/macos/homebrew.nix
    ../modules/macos/kanata.nix
  ]
  ++ optionals isHomeManagerStandalone [
    ../modules/home
    ../modules/common/packages.nix
  ];
}
// optionalAttrs isHomeManagerStandalone {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = { inherit inputs username; };
}
