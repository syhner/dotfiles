# Local voice dictation: hold a key, speak, and it pastes. The flake only
# builds Hex for Linux.
{
  inputs,
  pkgs,
  platform,
  ...
}:
{
  tags = [ "gui" ];

  home =
    if platform.isDarwin then
      { }
    else
      {
        imports = [ inputs.hex.homeManagerModules.hex ];
        programs.hex = {
          enable = true;
          autostart = true;
          # The published release, rather than the flake's build from source.
          package = pkgs.callPackage ./package.nix { };
        };
      };

  system = if platform.isDarwin then { homebrew.casks = [ "anomalyco/tap/hex" ]; } else { };
}
