# nixpkgs only builds Cryptomator for Linux.
{
  lib,
  machine,
  unstable,
  ...
}:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.cryptomator ];
  system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "cryptomator" ]; };
}
