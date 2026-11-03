{
  inputs,
  link,
  pkgs,
  ...
}:
{
  tags = [ "base" ];
  packages = [ pkgs.tmux ];

  home = {
    home.file.".tmux/plugins/tpm".source = inputs.tpm;

    xdg.configFile."tmux/tmux.conf".source = link ./tmux.conf;
  };
}
