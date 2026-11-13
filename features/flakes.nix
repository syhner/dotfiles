# The nix command and flakes, which nh, nix-direnv and nix copy need.
{ config, lib, ... }:
{
  config = lib.mkIf config.features.flakes.enable {
    system.nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
