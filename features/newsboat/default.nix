{
  config,
  lib,
  pkgs,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.newsboat.enable {
    packages = [ pkgs.newsboat ];

    home = {
      home.file.".newsboat/config".source = symlinkToCheckout ./config;

      home.file.".newsboat/urls".source = symlinkToCheckout ./urls;
    };
  };
}
