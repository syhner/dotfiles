{
  inputs,
  pkgs,
  lib,
  enabled,
  ...
}:
let
  shared = import ./packages.nix {
    inherit
      inputs
      pkgs
      lib
      enabled
      ;
  };
in
{
  home.packages = shared.packages ++ shared.fonts;
  fonts.fontconfig.enable = true;
}
