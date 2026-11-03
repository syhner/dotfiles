# nixpkgs trails the macOS releases.
{ pkgs, platform, ... }:
{
  tags = [ "workstation" ];

  packages = if platform.isDarwin then [ ] else [ pkgs.unstable.t3code ];
  system = if platform.isDarwin then { homebrew.casks = [ "t3-code" ]; } else { };
}
