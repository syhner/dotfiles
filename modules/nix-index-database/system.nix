{ inputs, systemKey, ... }:

{
  imports = [ inputs.nix-index-database."${systemKey}Modules".default ];

  programs.nix-index-database.comma.enable = true;
}
