# nixpkgs only builds Cryptomator for Linux.
{ machine, unstable, ... }:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.cryptomator ];
  system = if machine.platform.isDarwin then { homebrew.casks = [ "cryptomator" ]; } else { };
}
