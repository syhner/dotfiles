# nixpkgs only builds Cryptomator for Linux.
{ platform, unstable, ... }:
{
  tags = [ "gui" ];

  packages = if platform.isDarwin then [ ] else [ unstable.cryptomator ];
  system = if platform.isDarwin then { homebrew.casks = [ "cryptomator" ]; } else { };
}
