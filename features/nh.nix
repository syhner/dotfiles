# nh builds and switches to a configuration (nh darwin/os/home switch),
# showing what changed first, and cleans up old generations (nh clean).
{
  config,
  lib,
  pkgs,
  repositoryPath,
  ...
}:
{
  config = lib.mkIf config.features.nh.enable {
    # NH_FLAKE is set in zsh.
    features.zsh.enable = true;
    # nh builds flakes with the nix command.
    features.flakes.enable = true;

    packages = [ pkgs.nh ];

    # Where nh finds the flake, so it doesn't need --flake or a path.
    home.programs.zsh.sessionVariables.NH_FLAKE = repositoryPath;
  };
}
