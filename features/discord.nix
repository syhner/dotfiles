# The nixpkgs build gets stuck installing its helper on macOS.
{
  config,
  lib,
  machine,
  unstable,
  ...
}:
{
  config = lib.mkIf config.features.discord.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    unfree = [
      "discord"
      "discord-unwrapped"
    ];

    packages = if machine.platform.isDarwin then [ ] else [ unstable.discord ];
    system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "discord" ]; };
  };
}
