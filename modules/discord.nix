# The nixpkgs build gets stuck installing its helper on macOS.
{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];
  # On Linux, discord wraps discord-unwrapped.
  unfree = [
    "discord"
    "discord-unwrapped"
  ];

  packages = if darwin then [ ] else [ pkgs.unstable.discord ];
  system = if darwin then { homebrew.casks = [ "discord" ]; } else { };
}
