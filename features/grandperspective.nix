{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.grandperspective.enable {
    packages = [ pkgs.grandperspective ];
  };
}
