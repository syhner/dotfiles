# Helium, a Chromium-based browser. nixpkgs doesn't have it.
{
  config,
  lib,
  machine,
  ...
}:
{
  config = lib.mkIf config.features.helium.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "helium-browser" ]; };
  };
}
