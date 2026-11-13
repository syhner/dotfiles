{
  config,
  lib,
  machine,
  symlinkToCheckout,
  ...
}:
{
  # macOS only
  config = lib.mkIf (config.features.linearmouse.enable && machine.platform.isDarwin) {
    # Homebrew, for the cask.
    features.darwin.enable = true;

    home = {
      xdg.configFile."linearmouse/linearmouse.json".source = symlinkToCheckout ./linearmouse.json;
    };

    system.homebrew.casks = [ "linearmouse" ];
  };
}
