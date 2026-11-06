# The nixpkgs build gets stuck installing its helper on macOS.
{ machine, unstable, ... }:
{
  tags = [ "gui" ];
  unfree = [
    "discord"
    "discord-unwrapped"
  ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.discord ];
  system = if machine.platform.isDarwin then { homebrew.casks = [ "discord" ]; } else { };
}
