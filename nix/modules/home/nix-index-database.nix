{ inputs, platform, ... }:

{
  imports = [
    (
      {
        nixos = inputs.nix-index-database.nixosModules.default;
        darwin = inputs.nix-index-database.darwinModules.nix-index;
        home = inputs.nix-index-database.homeModules.default;
      }
      .${platform}
    )
  ];
}
