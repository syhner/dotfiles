# What every Mac gets.
{ config, lib, ... }:
{
  # Defaults, so a machine can still turn any of them off.
  config = lib.mkIf config.features.profiles.darwin.enable {
    features = lib.mkDefault {
      darwin.enable = true;
      deskflow.enable = true;
      grandperspective.enable = true;
      helium.enable = true;
      kanata.enable = true;
      linearmouse.enable = true;
      tailscale.enable = true;
      utm.enable = true;
    };
  };
}
