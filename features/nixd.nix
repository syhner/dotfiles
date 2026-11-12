{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.nixd.enable {
    packages = [ pkgs.nixd ];
  };
}
