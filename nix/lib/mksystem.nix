{
  inputs,
  nixpkgs,
  username ? "siraj",
}:

{
  system,
  hostname,
  enableNixosModules ? true,
  enableHomeManagerModules ? true,
  enableDarwinModules ? true,
  enableCommonModules ? true,
}:

let
  platform =
    if (system == "x86_64-linux" || system == "aarch64-linux") then
      "nixos"
    else if (system == "x86_64-darwin" || system == "aarch64-darwin") then
      "darwin"
    else
      "home";

  mkSystem =
    if (platform == "darwin") then
      inputs.nix-darwin.lib.darwinSystem
    else if (platform == "nixos") then
      nixpkgs.lib.nixosSystem
    else if (platform == "home") then
      inputs.home-manager.lib.homeManagerConfiguration
    else
      throw "Unknown platform: ${platform}";

  inherit (nixpkgs.lib) optionals optionalAttrs;
in
mkSystem {
  inherit system;
  specialArgs = { inherit inputs username hostname; };

  modules = [
    inputs.stylix."${platform}Modules".stylix
    ../modules/home/stylix.nix
  ]
  ++ optionals (platform == "home") [
    inputs.nix-index-database."${platform}Modules".default
    ../modules/home
  ]
  ++ optionals (enableCommonModules && (platform == "nixos" || platform == "darwin")) [
    ../hosts/${hostname}/configuration.nix
    ../modules/common/nix.nix
    ../modules/common/packages.nix
    ../modules/common/shell-zsh.nix
  ]
  ++ optionals (enableHomeManagerModules && platform == "nixos" || platform == "darwin") [
    inputs.home-manager."${platform}Modules".home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs username; };
      home-manager.users.${username} = ../modules/home;
    }
  ]
  ++ optionals (enableNixosModules && platform == "nixos") [
    ../modules/nixos/base.nix
    ../modules/nixos/graphical.nix
    inputs.nix-index-database."${platform}Modules".default
  ]
  ++ optionals (enableDarwinModules && platform == "darwin") [
    ../modules/macos/base.nix
    ../modules/macos/homebrew.nix
    ../modules/macos/kanata.nix
    inputs.nix-index-database."${platform}Modules".nix-index
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
}
// optionalAttrs (platform == "home") {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = { inherit inputs username; };
}
