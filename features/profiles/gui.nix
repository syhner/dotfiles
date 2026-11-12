# Desktop apps, for a machine with a screen.
{ config, lib, ... }:
{
  # Defaults, so a machine can still turn any of them off.
  config = lib.mkIf config.features.profiles.gui.enable {
    features = lib.mkDefault {
      cryptomator.enable = true;
      discord.enable = true;
      generic-linux.gpu = true;
      ghostty.enable = true;
      hex.enable = true;
      nerd-fonts.enable = true;
      obs.enable = true;
      obsidian.enable = true;
      proton-vpn.enable = true;
      qbittorrent.enable = true;
      spotify.enable = true;
      steam.enable = true;
      t3code.enable = true;
      thunderbird.enable = true;
      vlc.enable = true;
      zed.enable = true;
    };
  };
}
