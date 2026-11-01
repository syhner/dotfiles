{ inputs, pkgs, ... }:
let
  # No prebuilt database for x86_64-darwin.
  hasDatabase = pkgs.stdenv.hostPlatform.system != "x86_64-darwin";
in
{
  imports = [ inputs.nix-index-database.homeModules.default ];

  programs.nix-index.enable = hasDatabase;
  programs.nix-index-database.comma.enable = hasDatabase;
}
