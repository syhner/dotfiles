{
  config,
  repositoryPath,
  inputs,
  ...
}:
{
  home.file.".tmux/plugins/tpm".source = inputs.tpm;

  home.file.".config/tmux/tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/tmux/tmux.conf";
}
