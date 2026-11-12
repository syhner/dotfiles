{
  config,
  lib,
  machine,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.linearmouse.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    home = {
      xdg.configFile."linearmouse/linearmouse.json".source = symlinkToCheckout ./linearmouse.json;
    };

    system.homebrew.casks = [ "linearmouse" ];
  };
}
