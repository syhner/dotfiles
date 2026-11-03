{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if darwin then pkgs.vlc-bin else pkgs.vlc)
  ];
}
