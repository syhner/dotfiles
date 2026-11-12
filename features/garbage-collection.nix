# Collecting garbage, weekly, with nh clean: old generations go, keeping at
# least the last 5 and any from the past week, and then whatever nothing
# keeps alive. Not on a machine that serves a cache (see
# fleet-substituters.nix): its store is the cache, and nothing keeps what's
# copied there alive.
#
# Optimising the store, on NixOS and nix-darwin: identical files are
# hardlinked together. That deletes nothing, so a cache gets it too.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
let
  collect = !(import ./fleet-access/roles.nix).caches config.features;

  keep = [
    "--keep"
    "5"
    "--keep-since"
    "7d"
  ];
in
{
  config = lib.mkIf config.features.garbage-collection.enable {
    system =
      if machine.platform.isLinux then
        {
          nix.optimise.automatic = true;

          # A systemd timer, which runs a missed collection after boot.
          programs.nh.clean = lib.mkIf collect {
            enable = true;
            extraArgs = toString keep;
          };
        }
      else
        (
          { config, ... }:
          {
            # Sundays at 04:15.
            nix.optimise.automatic = true;

            # nix-darwin has no nh module. Sundays at 03:15, before the
            # optimiser, so it doesn't hardlink what's about to go. A Mac that's
            # asleep then runs it when it wakes.
            launchd.daemons.nh-clean = lib.mkIf collect {
              serviceConfig = {
                ProgramArguments = [
                  (lib.getExe pkgs.nh)
                  "clean"
                  "all"
                ]
                ++ keep;
                EnvironmentVariables = {
                  # nh runs nix.
                  PATH = "${config.nix.package}/bin:/usr/bin:/bin";
                  HOME = "/var/root";
                };
                StartCalendarInterval = [
                  {
                    Weekday = 7;
                    Hour = 3;
                    Minute = 15;
                  }
                ];
                StandardErrorPath = "/var/log/nh-clean.log";
              };
            };
          }
        );

    # A standalone home cleans its own generations, and then the store, as
    # the user. In a system, the system's nh clean all covers it.
    home = lib.optional machine.standalone {
      programs.nh.clean = {
        enable = true;
        extraArgs = toString keep;
      };

      # Home Manager's launchd agent passes extraArgs as one argument, which nh rejects.
      launchd.agents.nh-clean.config.ProgramArguments = lib.mkIf machine.platform.isDarwin (
        lib.mkForce (
          [
            (lib.getExe pkgs.nh)
            "clean"
            "user"
          ]
          ++ keep
        )
      );
    };
  };
}
