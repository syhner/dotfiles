{
  pkgs,
  platform,
  repositoryPath,
  ...
}:
{
  tags = [ "darwin" ];

  packages = [
    pkgs.zed-editor
    pkgs.nixfmt
  ];

  home =
    { config, ... }:
    {
      home.file.".config/zed/keymap.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/keymap.json";

      home.file.".config/zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/settings.json";

      home.file.${
        if platform.isDarwin then
          "Library/Application Support/Zed/Extensions/index.json"
        else
          "${config.home.homeDirectory}/.local/share/zed/extensions/index.json"
      }.source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/zed/extensions.json";
    };
}
