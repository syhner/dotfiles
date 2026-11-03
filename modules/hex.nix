# Local voice dictation: hold a key, speak, and it pastes. The flake only
# builds Hex for Linux.
{ darwin, inputs, ... }:
{
  tags = [ "workstation" ];

  home =
    if darwin then
      { }
    else
      {
        imports = [ inputs.hex.homeManagerModules.hex ];
        programs.hex = {
          enable = true;
          autostart = true;
        };
      };

  system = if darwin then { homebrew.casks = [ "anomalyco/tap/hex" ]; } else { };
}
