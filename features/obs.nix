# nixpkgs only builds OBS for Linux.
{
  lib,
  machine,
  pkgs,
  ...
}:
{
  tags = [ "gui" ];

  packages = if machine.platform.isDarwin then [ ] else [ pkgs.obs-studio ];
  system = lib.optionalAttrs machine.platform.isDarwin { homebrew.casks = [ "obs" ]; };
}
