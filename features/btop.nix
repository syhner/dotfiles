{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.btop.enable {
    packages = [ pkgs.btop ];
  };
}
