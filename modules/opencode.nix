{ pkgs, ... }:
{
  tags = [ "workstation" ];
  packages = [ pkgs.unstable.opencode ];
}
