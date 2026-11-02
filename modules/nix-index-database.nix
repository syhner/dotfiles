{
  tags = [ "workstation" ];

  home =
    {
      inputs,
      lib,
      pkgs,
      standalone,
      ...
    }:
    let
      # No prebuilt database for x86_64-darwin.
      hasDatabase = pkgs.stdenv.hostPlatform.system != "x86_64-darwin";
    in
    # Does the system part's job when Home Manager runs standalone.
    lib.optionalAttrs standalone {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index.enable = hasDatabase;
      programs.nix-index-database.comma.enable = hasDatabase;
    };

  system =
    { inputs, systemKey, ... }:

    {
      imports = [ inputs.nix-index-database."${systemKey}Modules".default ];

      programs.nix-index-database.comma.enable = true;
    };
}
