# What every NixOS system gets.
{ config, lib, ... }:
{
  # Defaults, so a machine can still turn any of them off.
  config = lib.mkIf config.features.profiles.nixos.enable {
    features = lib.mkDefault {
      nixos.enable = true;
      tailscale.enable = true;
    };
  };
}
