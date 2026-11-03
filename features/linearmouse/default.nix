{ link, ... }:
{
  tags = [ "darwin" ];

  home = {
    xdg.configFile."linearmouse/linearmouse.json".source = link ./linearmouse.json;
  };

  system.homebrew.casks = [ "linearmouse" ];
}
