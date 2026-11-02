{
  tags = [ "workstation" ];

  packages = pkgs: [
    # nixpkgs can't build the macOS app, so it repackages the official one.
    (if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty)
  ];

  home =
    {
      config,
      repositoryPath,
      ...
    }:
    {
      home.file.".config/ghostty/config".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/ghostty/config";
    };
}
