# nixpkgs trails the macOS releases.
{ platform, unstable, ... }:
{
  tags = [ "gui" ];

  packages = if platform.isDarwin then [ ] else [ unstable.t3code ];
  system = if platform.isDarwin then { homebrew.casks = [ "t3-code" ]; } else { };
}
