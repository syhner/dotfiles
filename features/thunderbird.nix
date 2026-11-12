{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.thunderbird.enable {
    packages = [ pkgs.thunderbird ];
  };
}
