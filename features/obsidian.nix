{ pkgs, ... }:
{
  tags = [ "gui" ];
  unfree = [ "obsidian" ];
  packages = [ pkgs.obsidian ];
}
