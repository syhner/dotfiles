{ link, pkgs, ... }@args:
let
  # Allowed to run shell commands.
  kanataWithCmd = pkgs.kanata.override { withCmd = true; };

  # Where kanata's config goes, under ~/.config. The system part's daemon
  # reads it from there too.
  configFile = "kanata/kanata.kbd";
in
{
  tags = [ "darwin" ];

  packages = [
    kanataWithCmd
    # nix-darwin puts the Karabiner manager that the system part runs in
    # /Applications/Nix Apps.
    pkgs.karabiner-dk
  ];

  home = {
    xdg.configFile.${configFile}.source = link ./kanata.kbd;
  };

  system = import ./system.nix (args // { inherit configFile kanataWithCmd; });
}
