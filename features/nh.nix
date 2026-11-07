# nh builds and switches to a configuration (nh darwin/os/home switch),
# showing what changed first, and cleans up old generations (nh clean).
{ pkgs, repositoryPath, ... }:
{
  tags = [ "base" ];

  packages = [ pkgs.nh ];

  # Where nh finds the flake, so it doesn't need --flake or a path.
  home.programs.zsh.sessionVariables.NH_FLAKE = repositoryPath;
}
