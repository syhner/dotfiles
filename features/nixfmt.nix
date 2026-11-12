{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.nixfmt.enable {
    packages = [ pkgs.nixfmt ];
  };
}
