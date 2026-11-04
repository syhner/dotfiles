{
  inputs,
  platform,
  standalone,
  ...
}:
let
  settings = {
    stylix.enable = true;
    # A copy of the scheme from pkgs.base16-schemes. Stylix reads it during
    # evaluation, and reading it from the package would mean building or
    # downloading that package first, for the configuration's platform.
    stylix.base16Scheme = ./tokyo-night-dark.yaml;
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
    imports = [ inputs.stylix.${if platform.isDarwin then "darwinModules" else "nixosModules"}.stylix ];
  }
  // settings;
}
