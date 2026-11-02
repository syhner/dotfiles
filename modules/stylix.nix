let
  settings = pkgs: {
    stylix.enable = true;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  };
in
{
  tags = [ "base" ];

  home =
    {
      inputs,
      lib,
      pkgs,
      standalone,
      ...
    }:
    # Does the system part's job when Home Manager runs standalone.
    lib.optionalAttrs standalone (
      {
        imports = [ inputs.stylix.homeModules.stylix ];
      }
      // settings pkgs
    );

  system =
    {
      inputs,
      systemKey,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.stylix."${systemKey}Modules".stylix ];
    }
    // settings pkgs;
}
