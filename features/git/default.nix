{ link, pkgs, ... }:
{
  tags = [ "base" ];

  packages = [
    pkgs.git
    pkgs.git-crypt
  ];

  home = {
    home.file.".gitconfig".source = link ./.gitconfig;

    # Where git looks for global ignores when core.excludesFile is unset.
    xdg.configFile."git/ignore".source = link ./.gitignore_global;
  };
}
