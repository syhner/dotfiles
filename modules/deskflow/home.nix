{
  config,
  lib,
  pkgs,
  repositoryPath,
  ...
}:
{
  home.file."Library/Deskflow/deskflow-server.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/deskflow/deskflow-server.conf";
    force = true;
  };

  # The GUI regenerates deskflow-server.conf unless external configuration is enabled.
  home.activation.enableDeskflowExternalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settingsFile="${config.home.homeDirectory}/Library/Deskflow/Deskflow.conf"
    if [[ -f "$settingsFile" ]]; then
      ${pkgs.perl}/bin/perl -0pi -e 's/^externalConfig=false$/externalConfig=true/m' "$settingsFile"
    fi
  '';
}
