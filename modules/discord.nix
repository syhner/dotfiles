# The nixpkgs build gets stuck installing its helper on macOS.
{ pkgs, platform, ... }:
{
  tags = [ "workstation" ];

  packages = if platform.isDarwin then [ ] else [ pkgs.unstable.discord ];
  system = if platform.isDarwin then { homebrew.casks = [ "discord" ]; } else { };
}
