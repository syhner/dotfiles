{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.obsidian.enable {
    unfree = [ "obsidian" ];
    packages = [ pkgs.obsidian ];
  };
}
