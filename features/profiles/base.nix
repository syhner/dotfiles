# What every machine gets.
{ config, lib, ... }:
{
  # Defaults, so a machine can still turn any of them off.
  config = lib.mkIf config.features.profiles.base.enable {
    features = lib.mkDefault {
      btop.enable = true;
      cli.enable = true;
      fleet-access.enable = true;
      fleet-builders.enable = true;
      fleet-substituters.enable = true;
      flakes.enable = true;
      garbage-collection.enable = true;
      generic-linux.enable = true;
      git.enable = true;
      gpg.enable = true;
      newsboat.enable = true;
      nh.enable = true;
      nix.enable = true;
      secrets.enable = true;
      ssh.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
  };
}
