# Local voice dictation: hold a key, speak, and it pastes.
{
  tags = [ "workstation" ];

  # The flake only builds Hex for Linux. Its module does nothing until
  # enabled, so it's safe to import everywhere.
  home =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.hex.homeManagerModules.hex ];
      programs.hex = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        autostart = true;
      };
    };

  system =
    { lib, systemKey, ... }:
    lib.optionalAttrs (systemKey == "darwin") {
      homebrew.casks = [ "anomalyco/tap/hex" ];
    };
}
