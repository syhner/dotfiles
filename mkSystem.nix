{
  inputs,
  nixpkgs,
  username,
  repositoryPath,
  ...
}:

{
  system,
  hostname ? null,
  # "system-module" | "standalone"
  homeManager ? "system-module",
  ...
}:

let
  systemKey =
    if homeManager == "standalone" then
      "home"
    else if system == "x86_64-linux" || system == "aarch64-linux" then
      "nixos"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  mkSystem =
    {
      darwin = inputs.nix-darwin.lib.darwinSystem;
      nixos = nixpkgs.lib.nixosSystem;
      home = inputs.home-manager.lib.homeManagerConfiguration;
    }
    .${systemKey};

  kernel =
    if system == "x86_64-linux" || system == "aarch64-linux" then
      "linux"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  # arch-os = builtins.split "-" system;
  # # "x86_86" | "aarch64"
  # # architecture = builtins.elemAt arch-os 0;
  # # "linux" | "darwin"
  # kernel = builtins.elemAt arch-os 1;

  specialArgs = {
    inherit
      inputs
      username
      hostname
      homeManager
      repositoryPath
      systemKey
      kernel
      ;
  };

in
mkSystem {
  inherit system;
  inherit specialArgs;

  modules = [
    ./hosts/${hostname}/configuration.nix
    ./modules/darwin/base.nix
    ./modules/git/system.nix
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
  ++ nixpkgs.lib.optionals (homeManager == "standalone") [
    ./home.nix
  ];
}
// nixpkgs.lib.optionalAttrs (homeManager == "standalone") {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = specialArgs;
}
