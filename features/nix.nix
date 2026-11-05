{ settings, ... }:
{
  tags = [ "base" ];

  system.nix.settings = {
    # Enable modern nix command UX + flakes
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # What CI builds that cache.nixos.org doesn't have. The extra- settings
    # add to the defaults rather than replacing them.
    extra-substituters = [ "https://${settings.cache.name}.cachix.org" ];
    extra-trusted-public-keys = [ settings.cache.publicKey ];
  };
}
