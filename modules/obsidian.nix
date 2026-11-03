{ pkgs, ... }:
{
  tags = [ "workstation" ];
  unfree = [ "obsidian" ];
  packages = [ pkgs.obsidian ];
}
