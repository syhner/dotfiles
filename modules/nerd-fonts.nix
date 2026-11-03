# Fonts aren't packages: the system and Home Manager each install them their
# own way.
{ pkgs, standalone, ... }:
let
  fonts = [ pkgs.nerd-fonts.jetbrains-mono ];
in
{
  tags = [ "workstation" ];

  home =
    if standalone then
      {
        home.packages = fonts;
        fonts.fontconfig.enable = true;
      }
    else
      { };

  system.fonts.packages = fonts;
}
