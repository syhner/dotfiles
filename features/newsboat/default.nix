{ pkgs, symlinkToCheckout, ... }:
{
  tags = [ "base" ];
  packages = [ pkgs.newsboat ];

  home = {
    home.file.".newsboat/config".source = symlinkToCheckout ./config;

    home.file.".newsboat/urls".source = symlinkToCheckout ./urls;
  };
}
