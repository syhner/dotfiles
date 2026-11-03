{
  inputs,
  platform,
  standalone,
  ...
}:
{
  tags = [ "dev" ];

  # Does the system part's job when Home Manager runs standalone.
  home =
    if standalone then
      {
        imports = [ inputs.nix-index-database.homeModules.default ];

        programs.nix-index.enable = true;
        programs.nix-index-database.comma.enable = true;
      }
    else
      { };

  system = {
    imports = [
      inputs.nix-index-database.${if platform.isDarwin then "darwinModules" else "nixosModules"}.default
    ];

    programs.nix-index-database.comma.enable = true;
  };
}
