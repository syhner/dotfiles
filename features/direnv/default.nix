{
  config,
  lib,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.direnv.enable {
    # for nix-direnv's use flake
    features.flakes.enable = true;

    home = {
      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;

      xdg.configFile."direnv/direnv.toml".source = symlinkToCheckout ./direnv.toml;
    };
  };
}
