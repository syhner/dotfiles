# Fonts aren't packages: the system and Home Manager each install them their
# own way.
{ machine, pkgs, ... }:
let
  fonts = [ pkgs.nerd-fonts.jetbrains-mono ];
in
{
  tags = [ "gui" ];

  home =
    if machine.standalone then
      {
        home.packages = fonts;
        fonts.fontconfig.enable = true;
      }
    else
      { };

  system.fonts.packages = fonts;
}
