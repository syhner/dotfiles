# Fonts aren't packages: the system and Home Manager each install them their
# own way.
let
  fonts = pkgs: [ pkgs.nerd-fonts.jetbrains-mono ];
in
{
  tags = [ "workstation" ];

  home =
    {
      lib,
      pkgs,
      standalone,
      ...
    }:
    lib.optionalAttrs standalone {
      home.packages = fonts pkgs;
      fonts.fontconfig.enable = true;
    };

  system =
    { pkgs, ... }:
    {
      fonts.packages = fonts pkgs;
    };
}
