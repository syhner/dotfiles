# nixpkgs only builds Cryptomator for Linux.
{ pkgs, platform, ... }:
{
  tags = [ "workstation" ];

  packages = if platform.isDarwin then [ ] else [ pkgs.unstable.cryptomator ];
  system = if platform.isDarwin then { homebrew.casks = [ "cryptomator" ]; } else { };
}
