# nixpkgs only builds Cryptomator for Linux.
{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];

  packages = if darwin then [ ] else [ pkgs.unstable.cryptomator ];
  system = if darwin then { homebrew.casks = [ "cryptomator" ]; } else { };
}
