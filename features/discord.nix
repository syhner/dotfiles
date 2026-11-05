# The nixpkgs build gets stuck installing its helper on macOS.
{ platform, unstable, ... }:
{
  tags = [ "gui" ];
  unfree = [
    "discord"
    "discord-unwrapped"
  ];

  packages = if platform.isDarwin then [ ] else [ unstable.discord ];
  system = if platform.isDarwin then { homebrew.casks = [ "discord" ]; } else { };
}
