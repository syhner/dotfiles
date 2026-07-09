{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  shared = import ./packages.nix { inherit inputs pkgs lib; };
in
{
  home.packages = shared.packages ++ shared.fonts;
  fonts.fontconfig.enable = true;
}
