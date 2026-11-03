{ pkgs, platform, ... }:
{
  tags = [ "gui" ];

  packages = [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if platform.isDarwin then pkgs.vlc-bin else pkgs.vlc)
  ];
}
