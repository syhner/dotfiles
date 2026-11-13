{
  config,
  lib,
  machine,
  pkgs,
  symlinkToCheckout,
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
  config = lib.mkIf config.features.zed.enable {
    # Zed checks and formats Nix with them.
    features.nixd.enable = true;
    features.nixfmt.enable = true;
    # runs the Node and language servers Zed downloads, on NixOS
    features.nix-ld.enable = true;

    packages = [
      pkgs.zed-editor
      # the `zed` CLI that the command palette's "install cli" would add
      (pkgs.runCommandLocal "zed-cli" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.zed-editor}/bin/zeditor $out/bin/zed
      '')
    ];

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
        xdg.configFile."zed/keymap.json".source = symlinkToCheckout ./keymap.json;

        xdg.configFile."zed/settings.json".source = symlinkToCheckout ./settings.json;

        home.file."${extensionsDir}/index.json".source = symlinkToCheckout ./extensions.json;

        home.file."${extensionsDir}/installed/material-icon-theme-plain-folders".source =
          plainFolderIconTheme;
      };
  };
}
