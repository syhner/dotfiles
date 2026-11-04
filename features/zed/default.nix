{
  link,
  pkgs,
  platform,
  ...
}:
{
  tags = [ "gui" ];

  packages = [ pkgs.zed-editor ];

  home =
    { config, ... }:
    {
      xdg.configFile."zed/keymap.json".source = link ./keymap.json;

      xdg.configFile."zed/settings.json".source = link ./settings.json;

      home.file.${
        if platform.isDarwin then
          "Library/Application Support/Zed/Extensions/index.json"
        else
          "${config.xdg.dataHome}/zed/extensions/index.json"
      }.source =
        link ./extensions.json;
    };
}
