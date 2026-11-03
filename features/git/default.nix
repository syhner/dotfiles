{ pkgs, repositoryPath, ... }:
{
  tags = [ "base" ];

  packages = [
    pkgs.git
    pkgs.git-crypt
  ];

  home =
    { config, ... }:
    {
      home.file.".gitconfig".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/git/.gitconfig";

      # Where git looks for global ignores when core.excludesFile is unset.
      xdg.configFile."git/ignore".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/git/.gitignore_global";
    };
}
