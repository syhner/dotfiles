{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Authentication subkey AA8B5B6A631DE5A0; private keys stay outside Nix.
    sshKeys = [ "B274E0254887838C15461704E6D23BB68C7B35CF" ];
    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };

  # Follow nix-darwin's startup pattern on macOS: GnuPG creates its own
  # sockets, matching the paths returned by gpgconf in the shell integration.
  launchd.agents.gpg-agent = lib.mkIf pkgs.stdenv.isDarwin {
    config.ProgramArguments = lib.mkForce [
      "${config.programs.gpg.package}/bin/gpg-connect-agent"
      "/bye"
    ];
    config.Sockets = lib.mkForce { };
  };

  # Apply changed pinentry settings to an agent that was already running.
  home.activation.reloadGpgAgent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${config.programs.gpg.package}/bin/gpgconf --reload gpg-agent
  '';
}
