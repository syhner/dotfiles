{
  config,
  lib,
  pkgs,
  settings,
  symlinkToCheckout,
  ...
}:
let
  # Allowed to run shell commands. The packages part installs it, and the
  # system part's daemon runs the same build.
  kanataWithCmd = pkgs.kanata.override { withCmd = true; };

  # Where kanata's config goes, under ~/.config. The system part's daemon
  # reads it from there too.
  configFile = "kanata/kanata.kbd";
in
{
  config = lib.mkIf config.features.kanata.enable {
    packages = [ kanataWithCmd ];

    home = {
      xdg.configFile.${configFile}.source = symlinkToCheckout ./kanata.kbd;
    };

    system =
      { config, ... }:
      let
        # The virtual HID driver version this kanata build speaks to.
        driver = kanataWithCmd.darwinDriver;

        stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
        stableKanataBin = "${stableKanataDir}/kanata";
        stableKanataPackage = "${stableKanataDir}/package";

        realKanataBin = lib.getExe kanataWithCmd;

        # nix-darwin copies it there from systemPackages, below. macOS only
        # activates a driver extension from an app under /Applications.
        karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";

        vhidDaemon = "${driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
      in
      {
        # macOS ties the Input Monitoring and Accessibility permissions to the
        # binary, so kanata runs from a copy that's only replaced when the
        # binary changes. Comparing the binary rather than the version also
        # catches a rebuild that keeps the version. The GC root keeps the
        # package it was copied from, and so the libraries the copy links to,
        # alive. It's swapped in with mv, so a restart never finds it missing,
        # and Kanata is restarted to run it (launchd only restarts it itself
        # when its plist changes).
        system.activationScripts.preActivation.text = ''
          install -d -m 0755 ${stableKanataDir}

          if [ ! -x ${stableKanataBin} ] || [ ! -e ${stableKanataPackage} ] ||
            ! cmp -s ${realKanataBin} ${stableKanataBin}; then
            install -m 0755 ${realKanataBin} ${stableKanataBin}.new
            mv -f ${stableKanataBin}.new ${stableKanataBin}
            rm -f ${stableKanataPackage}
            ${pkgs.nix}/bin/nix-store --add-root ${stableKanataPackage} --indirect -r ${kanataWithCmd} >/dev/null
            /bin/launchctl kickstart -k system/org.nixos.kanata 2>/dev/null || true

            cat <<'EOF'

          Kanata was replaced, so macOS may need its permissions granted again.
          Remove any old entry, then add and enable ${stableKanataBin} under:
            System Settings → Privacy & Security → Input Monitoring
            System Settings → Privacy & Security → Accessibility

          EOF
          fi
        '';

        # Does nothing once the extension is active. The first time, approve it
        # under System Settings → General → Login Items & Extensions → Driver
        # Extensions.
        system.activationScripts.postActivation.text = ''
          ${lib.escapeShellArg karabinerManager} activate >/dev/null || true
        '';

        environment.systemPackages = [ driver ];

        launchd.daemons.kanata = {
          serviceConfig = {
            ProgramArguments = [
              stableKanataBin
              "--cfg"
              "${config.home-manager.users.${settings.username}.xdg.configHome}/${configFile}"
            ];
            RunAtLoad = true;
            KeepAlive = true;
            ProcessType = "Interactive";
            StandardOutPath = "/tmp/kanata.out.log";
            StandardErrorPath = "/tmp/kanata.err.log";
          };
        };

        launchd.daemons.karabiner-vhid = {
          serviceConfig = {
            # launchd rejects the daemon in the Nix store as a missing executable,
            # because Nix packaging invalidates its upstream code signature.
            # Apple's signed shell starts it as sudo in a terminal would.
            ProgramArguments = [
              "/bin/sh"
              "-c"
              ''exec "$1"''
              "karabiner-vhid"
              vhidDaemon
            ];
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 5;
            StandardOutPath = "/tmp/karabiner-vhid.out.log";
            StandardErrorPath = "/tmp/karabiner-vhid.err.log";
          };
        };
      };
  };
}
