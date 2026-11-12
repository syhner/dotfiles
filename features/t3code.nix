# nixpkgs trails the macOS releases.
{
  config,
  lib,
  machine,
  unstable,
  ...
}:
{
  config = lib.mkIf config.features.t3code.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    packages = if machine.platform.isDarwin then [ ] else [ unstable.t3code ];
    system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "t3-code" ]; };
  };
}
