# nixpkgs only builds OBS for Linux.
{ pkgs, platform, ... }:
{
  tags = [ "gui" ];

  packages = if platform.isDarwin then [ ] else [ pkgs.obs-studio ];
  system = if platform.isDarwin then { homebrew.casks = [ "obs" ]; } else { };
}
