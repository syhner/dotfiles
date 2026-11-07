{
  machine,
  pkgs,
  settings,
  symlinkToCheckout,
  ...
}:
{
  tags = [ "base" ];

  home =
    { config, lib, ... }:
    lib.mkMerge [
      {
        programs.gpg.enable = true;

        programs.gpg.publicKeys = [
          {
            source = ./public.asc;
            trust = "ultimate";
          }
        ];

        services.gpg-agent = {
          enable = true;
          enableSshSupport = true;
          sshKeys = [ settings.sshKeygrip ];
          pinentry.package = if machine.platform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
        };

        # Apply changed pinentry settings to an agent that was already running.
        home.activation.reloadGpgAgent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${config.programs.gpg.package}/bin/gpgconf --reload gpg-agent
        '';
      }
      (lib.optionalAttrs machine.platform.isDarwin {
        # Follow nix-darwin's startup pattern on macOS: GnuPG creates its own
        # sockets, matching the paths returned by gpgconf in the shell
        # integration.
        launchd.agents.gpg-agent = {
          config.ProgramArguments = lib.mkForce [
            "${config.programs.gpg.package}/bin/gpg-connect-agent"
            "/bye"
          ];
          config.Sockets = lib.mkForce { };
        };

        home.file.".ssh/config".source = symlinkToCheckout ./ssh_config;
      })
    ];
}
