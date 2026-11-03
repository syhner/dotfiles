{ pkgs, ... }:
{
  tags = [ "workstation" ];
  unfree = [ "claude-code" ];
  packages = [ pkgs.unstable.claude-code ];
}
