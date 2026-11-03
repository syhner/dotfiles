{ pkgs, ... }:
{
  tags = [ "workstation" ];
  packages = [ pkgs.unstable.claude-code ];
}
