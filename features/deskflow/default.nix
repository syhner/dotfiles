{
  config,
  lib,
  homeDirectory,
  inputs,
  machine,
  pkgs,
  symlinkToCheckout,
  ...
}:
{
  config = lib.mkIf config.features.deskflow.enable {
    # Homebrew, for the cask.
    features.darwin.enable = lib.mkIf machine.platform.isDarwin true;

    home =
      { lib, ... }:
      {
        home.file."Library/Deskflow/deskflow-server.conf" = {
          source = symlinkToCheckout ./deskflow-server.conf;
          force = true;
        };

        # The GUI regenerates deskflow-server.conf unless external configuration is enabled.
        home.activation.enableDeskflowExternalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settingsFile="${homeDirectory}/Library/Deskflow/Deskflow.conf"
          if [[ -f "$settingsFile" ]]; then
            ${pkgs.perl}/bin/perl -0pi -e 's/^externalConfig=false$/externalConfig=true/m' "$settingsFile"
          fi
        '';
      };

    system.nix-homebrew.taps."deskflow/homebrew-tap" = inputs.deskflow-tap;
    system.homebrew.casks = [
      {
        name = "deskflow/tap/deskflow";
        trusted = true;
      }
    ];
  };
}
