{
  link,
  machine,
  pkgs,
  ...
}:
let
  # Material Icon Theme with its per-name folder icons (src, nix, .github and
  # so on) removed, so every folder falls back to the plain folder icon while
  # files keep their icons. Installed as its own extension.
  plainFolderIconTheme =
    pkgs.runCommandLocal "zed-material-icon-theme-plain-folders"
      {
        src = pkgs.fetchFromGitHub {
          owner = "zed-extensions";
          repo = "material-icon-theme";
          rev = "v1.3.2";
          hash = "sha256-JmUoqaY7Udzy39s3/ruuneqLSE0btGrmUV28uTClkwc=";
        };
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        mkdir -p $out/icon_themes
        ln -s $src/icons $out/icons
        jq '.themes |= map(del(.named_directory_icons) | .name += " (Plain Folders)")' \
          $src/icon_themes/material-icon-theme.json > $out/icon_themes/material-icon-theme.json
        cat > $out/extension.toml <<EOF
        id = "material-icon-theme-plain-folders"
        name = "Material Icon Theme (Plain Folders)"
        version = "1.3.2"
        schema_version = 1
        description = "Material Design icons, with plain folder icons."
        repository = "https://github.com/zed-extensions/material-icon-theme"
        authors = ["Zed Industries <support@zed.dev>"]
        icon_themes = ["icon_themes/material-icon-theme.json"]
        EOF
      '';
in
{
  tags = [ "gui" ];

  packages = [ pkgs.zed-editor ];

  home =
    { config, ... }:
    let
      extensionsDir =
        if machine.platform.isDarwin then
          "Library/Application Support/Zed/Extensions"
        else
          "${config.xdg.dataHome}/zed/extensions";
    in
    {
      xdg.configFile."zed/keymap.json".source = link ./keymap.json;

      xdg.configFile."zed/settings.json".source = link ./settings.json;

      home.file."${extensionsDir}/index.json".source = link ./extensions.json;

      home.file."${extensionsDir}/installed/material-icon-theme-plain-folders".source =
        plainFolderIconTheme;
    };
}
