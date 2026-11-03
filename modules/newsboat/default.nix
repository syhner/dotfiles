{ pkgs, repositoryPath, ... }:
{
  tags = [ "base" ];
  packages = [ pkgs.newsboat ];

  home =
    { config, ... }:
    {
      home.file.".newsboat/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/newsboat/config";

      home.file.".newsboat/urls".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/newsboat/urls";
    };
}
