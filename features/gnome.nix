# A GNOME desktop. The rest of the desktop is in desktop.nix.
{ config, lib, ... }:
{
  config = lib.mkIf config.features.gnome.enable {
    # The rest of the desktop.
    features.desktop.enable = true;

    system = {
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;
    };
  };
}
