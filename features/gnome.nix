# A GNOME desktop. The rest of the desktop is in desktop.nix.
{ ... }:
{
  tags = [ "gnome" ];

  system = {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
