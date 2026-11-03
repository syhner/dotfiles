{ pkgs, ... }:
{
  tags = [ "workstation" ];
  unfree = [ "spotify" ];
  packages = [ pkgs.spotify ];
}
