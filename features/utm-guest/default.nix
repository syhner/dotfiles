# A NixOS VM running in UTM on the Mac.
{ ... }@args:
{
  tags = [ "utm-guest" ];

  system = [
    # Local network hostname discovery.
    ./avahi.nix
    # The folder UTM shares with the VM.
    ./share.nix
    # OpenSSH, with its port open.
    (import ./ssh.nix args)
    # The systemd-boot EFI boot loader.
    ./systemd-boot.nix
  ];
}
