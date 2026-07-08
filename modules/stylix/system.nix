{
  inputs,
  systemKey,
  pkgs,
  ...
}:
{
  imports = [ inputs.stylix."${systemKey}Modules".stylix ];

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
}
