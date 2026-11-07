{ symlinkToCheckout, ... }:
{
  tags = [ "darwin" ];

  home = {
    xdg.configFile."linearmouse/linearmouse.json".source = symlinkToCheckout ./linearmouse.json;
  };

  system.homebrew.casks = [ "linearmouse" ];
}
