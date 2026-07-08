{
  config,
  repositoryPath,
  ...
}:

{
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/nix/modules/git/.gitconfig";

  home.file.".gitignore_global".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/nix/modules/git/.gitignore_global";
}
