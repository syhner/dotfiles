# A KDE Plasma desktop, with the SDDM login screen on Wayland. The rest of
# the desktop is in desktop.nix.
{ config, lib, ... }:
{
  config = lib.mkIf config.features.plasma.enable {
    # The rest of the desktop.
    features.desktop.enable = true;

    system = {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      services.desktopManager.plasma6.enable = true;
    };
  };
}
