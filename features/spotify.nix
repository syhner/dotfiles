{ pkgs, ... }:
{
  tags = [ "gui" ];
  unfree = [ "spotify" ];
  packages = [ pkgs.spotify ];
}
