{ pkgs, ... }:
{
  tags = [ "dev" ];
  packages = [ pkgs.unstable.opencode ];
}
