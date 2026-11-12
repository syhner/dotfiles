{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.utm.enable {
    packages = [ pkgs.utm ];
  };
}
