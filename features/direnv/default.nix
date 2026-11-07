{ symlinkToCheckout, ... }:
{
  tags = [ "dev" ];

  home = {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    xdg.configFile."direnv/direnv.toml".source = symlinkToCheckout ./direnv.toml;
  };
}
