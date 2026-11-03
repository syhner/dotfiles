{ link, pkgs, ... }:
{
  tags = [ "base" ];
  packages = [ pkgs.newsboat ];

  home = {
    home.file.".newsboat/config".source = link ./config;

    home.file.".newsboat/urls".source = link ./urls;
  };
}
