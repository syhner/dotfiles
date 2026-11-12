# nixpkgs only builds OBS for Linux.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.obs.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    packages = if machine.platform.isDarwin then [ ] else [ pkgs.obs-studio ];
    system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "obs" ]; };
  };
}
