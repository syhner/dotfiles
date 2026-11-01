# Installs the packages and fonts the configuration's modules list (see
# nix/modules.nix): system-wide, or through Home Manager when it runs
# standalone. Integrated homes install nothing, the system does it for them.
{ modules, standalone }:
{ pkgs, lib, ... }:
let
  partOf =
    part:
    lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
      builtins.concatMap (module: (module.${part} or (pkgs: [ ])) pkgs) modules
    );
  packages = partOf "packages";
  fonts = partOf "fonts";
in
if standalone then
  {
    home.packages = packages ++ fonts;
    fonts.fontconfig.enable = lib.mkIf (fonts != [ ]) true;
  }
else
  {
    environment.systemPackages = packages;
    fonts.packages = fonts;
  }
