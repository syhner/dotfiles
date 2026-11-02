{
  tags = [ "workstation" ];

  packages = pkgs: [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if pkgs.stdenv.isDarwin then pkgs.vlc-bin else pkgs.vlc)
  ];
}
