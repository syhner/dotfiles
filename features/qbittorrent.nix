{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.qbittorrent.enable {
    packages = [ pkgs.qbittorrent ];
  };
}
