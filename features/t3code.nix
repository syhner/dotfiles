# nixpkgs trails the macOS releases.
{
  lib,
  machine,
  unstable,
  ...
}:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ unstable.t3code ];
  system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "t3-code" ]; };
}
