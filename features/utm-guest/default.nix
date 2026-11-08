# A NixOS VM running in UTM on the Mac.
{ ... }:
{
  tags = [ "utm-guest" ];

  system = [
    # Local network hostname discovery.
    ./avahi.nix
    # The folder UTM shares with the VM.
    ./share.nix
  ];
}
