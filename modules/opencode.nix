{
  tags = [ "workstation" ];

  packages = pkgs: [
    # Unstable nixpkgs no longer supports Intel macOS; use the stable package there.
    (
      if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then pkgs.opencode else pkgs.unstable.opencode
    )
  ];
}
