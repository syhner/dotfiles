{
  config,
  lib,
  settings,
  ...
}:
{
  config = lib.mkIf config.features.nix.enable {
    system.nix.settings = {
      # Enable modern nix command UX + flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # What CI builds that cache.nixos.org doesn't have. The extra- settings
      # add to the defaults rather than replacing them.
      extra-substituters = [ "https://${settings.cachix.name}.cachix.org" ];
      extra-trusted-public-keys = [ settings.cachix.publicKey ];

      warn-dirty = false;
    };
  };
}
