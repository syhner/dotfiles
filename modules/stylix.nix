{
  inputs,
  pkgs,
  standalone,
  systemKey,
  ...
}:
let
  settings = {
    stylix.enable = true;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  };
in
{
  tags = [ "base" ];

  # Does the system part's job when Home Manager runs standalone.
  home =
    if standalone then
      {
        imports = [ inputs.stylix.homeModules.stylix ];
      }
      // settings
    else
      { };

  system = {
    imports = [ inputs.stylix."${systemKey}Modules".stylix ];
  }
  // settings;
}
