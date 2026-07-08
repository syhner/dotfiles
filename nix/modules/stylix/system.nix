{
  inputs,
  platform,
  pkgs,
  ...
}:
{
  imports = [ inputs.stylix."${platform}Modules".stylix ];

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
}
