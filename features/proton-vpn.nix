{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.proton-vpn.enable {
    packages = [ pkgs.proton-vpn ];
  };
}
