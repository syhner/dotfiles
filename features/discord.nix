# The nixpkgs build gets stuck installing its helper on macOS.
{
  lib,
  machine,
  unstable,
  ...
}:
{
  tags = [ "gui" ];
  unfree = [
    "discord"
    "discord-unwrapped"
  ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.discord ];
  system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "discord" ]; };
}
