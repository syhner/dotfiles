# nixpkgs only builds OBS for Linux.
{ pkgs, platform, ... }:
{
  tags = [ "workstation" ];

  packages = if platform.isDarwin then [ ] else [ pkgs.obs-studio ];
  system = if platform.isDarwin then { homebrew.casks = [ "obs" ]; } else { };
}
