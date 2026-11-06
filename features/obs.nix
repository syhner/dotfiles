# nixpkgs only builds OBS for Linux.
{ machine, pkgs, ... }:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ pkgs.obs-studio ];
  system = if machine.platform.isDarwin then { homebrew.casks = [ "obs" ]; } else { };
}
