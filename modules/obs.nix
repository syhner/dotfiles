# nixpkgs only builds OBS for Linux.
{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];

  packages = if darwin then [ ] else [ pkgs.obs-studio ];
  system = if darwin then { homebrew.casks = [ "obs" ]; } else { };
}
