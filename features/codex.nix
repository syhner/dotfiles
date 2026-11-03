{ pkgs, ... }:
{
  tags = [ "dev" ];
  packages = [ pkgs.unstable.codex ];
}
