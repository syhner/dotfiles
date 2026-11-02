# Installs the packages the configuration's modules list (see nix/modules.nix):
# system-wide, or through Home Manager when it runs standalone, skipping any not
# available on the platform.
{ modules, standalone }:
{ pkgs, lib, ... }:
let
  packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
    builtins.concatMap (module: (module.packages or (pkgs: [ ])) pkgs) modules
  );
in
if standalone then { home.packages = packages; } else { environment.systemPackages = packages; }
