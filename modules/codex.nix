{ pkgs, ... }:
{
  tags = [ "workstation" ];
  packages = [ pkgs.unstable.codex ];
}
