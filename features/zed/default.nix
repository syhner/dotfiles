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
      xdg.configFile."zed/keymap.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/zed/keymap.json";

      xdg.configFile."zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/zed/settings.json";

      home.file.${
        if platform.isDarwin then
          "Library/Application Support/Zed/Extensions/index.json"
        else
          "${config.xdg.dataHome}/zed/extensions/index.json"
      }.source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/features/zed/extensions.json";
    };
}
