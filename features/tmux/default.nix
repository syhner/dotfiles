{
  inputs,
  pkgs,
  repositoryPath,
  ...
}:
{
  tags = [ "base" ];
  packages = [ pkgs.tmux ];

  home =
    { config, ... }:
    {
      home.file.".tmux/plugins/tpm".source = inputs.tpm;

      xdg.configFile."tmux/tmux.conf".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/tmux/tmux.conf";
    };
}
