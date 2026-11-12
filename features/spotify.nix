{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.spotify.enable {
    unfree = [ "spotify" ];
    packages = [ pkgs.spotify ];
  };
}
