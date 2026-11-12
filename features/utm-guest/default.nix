# A NixOS VM running in UTM on the Mac.
{ config, lib, ... }:
{
  config = lib.mkIf config.features.utm-guest.enable {
    # OpenSSH's key-only settings.
    features.ssh.enable = true;

    system = [
      # Local network hostname discovery.
      ./avahi.nix
      # The folder UTM shares with the VM.
      ./share.nix
      # OpenSSH as well as Tailscale SSH, key-only (see features/ssh).
      { services.openssh.enable = true; }
    ];
  };
}
