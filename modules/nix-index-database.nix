{
  inputs,
  pkgs,
  standalone,
  systemKey,
  ...
}:
let
  # No prebuilt database for x86_64-darwin.
  hasDatabase = pkgs.stdenv.hostPlatform.system != "x86_64-darwin";
in
{
  tags = [ "workstation" ];

  # Does the system part's job when Home Manager runs standalone.
  home =
    if standalone then
      {
        imports = [ inputs.nix-index-database.homeModules.default ];

        programs.nix-index.enable = hasDatabase;
        programs.nix-index-database.comma.enable = hasDatabase;
      }
    else
      { };

  system = {
    imports = [ inputs.nix-index-database."${systemKey}Modules".default ];

    programs.nix-index-database.comma.enable = true;
  };
}
