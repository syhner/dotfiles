# nixpkgs trails the macOS releases.
{ darwin, pkgs, ... }:
{
  tags = [ "workstation" ];

  packages = if darwin then [ ] else [ pkgs.unstable.t3code ];
  system = if darwin then { homebrew.casks = [ "t3-code" ]; } else { };
}
