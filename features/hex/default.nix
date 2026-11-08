# Local voice dictation: hold a key, speak, and it pastes. The flake only
# builds Hex for Linux.
{
  inputs,
  machine,
  pkgs,
  ...
}:
{
  tags = [ "gui" ];

  home =
    if machine.platform.isDarwin then
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

  system =
    if machine.platform.isDarwin then
      {
        nix-homebrew.taps."anomalyco/homebrew-tap" = inputs.hex-tap;
        homebrew.casks = [ "anomalyco/tap/hex" ];
      }
    else
      { };
}
