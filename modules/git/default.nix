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
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/git/.gitconfig";

      home.file.".gitignore_global".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/git/.gitignore_global";
    };
}
