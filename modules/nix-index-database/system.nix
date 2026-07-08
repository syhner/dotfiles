{ inputs, systemKey, ... }:

{
  imports = [
    (
      {
        nixos = inputs.nix-index-database.nixosModules.default;
        darwin = inputs.nix-index-database.darwinModules.nix-index;
        home = inputs.nix-index-database.homeModules.default;
      }
      .${systemKey}
    )
  ];

  programs.nix-index-database.comma.enable = true;
}
