# Fonts aren't packages: the system and Home Manager each install them their
# own way.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
let
  fonts = [ pkgs.nerd-fonts.jetbrains-mono ];
in
{
  config = lib.mkIf config.features.nerd-fonts.enable {
    home =
      if machine.standalone then
        {
          home.packages = fonts;
          fonts.fontconfig.enable = true;
        }
      else
        { };

    system.fonts.packages = fonts;
  };
}
