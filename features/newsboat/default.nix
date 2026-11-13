{
  config,
  lib,
  pkgs,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.newsboat.enable {
    # config's browser
    features.helium.enable = true;

    packages = [ pkgs.newsboat ];

    home = {
      home.file.".newsboat/config".source = symlinkToCheckout ./config;

      home.file.".newsboat/urls".source = symlinkToCheckout ./urls;
    };
  };
}
