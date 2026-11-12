# Development tools.
{ config, lib, ... }:
{
  # Defaults, so a machine can still turn any of them off.
  config = lib.mkIf config.features.profiles.dev.enable {
    features = lib.mkDefault {
      claude-code.enable = true;
      codex.enable = true;
      direnv.enable = true;
      nil.enable = true;
      nix-index-database.enable = true;
      nix-ld.enable = true;
      nixd.enable = true;
      nixfmt.enable = true;
      opencode.enable = true;
    };
  };
}
