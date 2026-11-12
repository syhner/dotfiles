{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.nil.enable {
    packages = [ pkgs.nil ];
  };
}
