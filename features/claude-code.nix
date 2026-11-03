{ pkgs, ... }:
{
  tags = [ "dev" ];
  packages = [ pkgs.unstable.claude-code ];
}
