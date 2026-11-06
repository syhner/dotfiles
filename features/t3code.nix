# nixpkgs trails the macOS releases.
{ machine, unstable, ... }:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.t3code ];
  system = if machine.platform.isDarwin then { homebrew.casks = [ "t3-code" ]; } else { };
}
