# nixpkgs only builds Cryptomator for Linux.
{
  config,
  lib,
  machine,
  unstable,
  ...
}:
{
  config = lib.mkIf config.features.cryptomator.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    packages = if machine.platform.isDarwin then [ ] else [ unstable.cryptomator ];
    system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "cryptomator" ]; };
  };
}
