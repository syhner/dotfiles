{
  tags = [ "darwin" ];

  packages = pkgs: [
    pkgs.zed-editor
    pkgs.nixfmt
  ];

  home =
    {
      config,
      pkgs,
      repositoryPath,
      ...
    }:

    {
      home.file.".config/zed/keymap.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/keymap.json";

      home.file.".config/zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/settings.json";

      home.file.${
        if pkgs.stdenv.isDarwin then
          "Library/Application Support/Zed/Extensions/index.json"
        else
          "${config.home.homeDirectory}/.local/share/zed/extensions/index.json"
      }.source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/extensions.json";
    };
}
