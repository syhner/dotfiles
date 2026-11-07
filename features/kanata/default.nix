{
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
  tags = [ "darwin" ];

  packages = [ kanataWithCmd ];

  home = {
    xdg.configFile.${configFile}.source = symlinkToCheckout ./kanata.kbd;
  };

  system =
    { config, ... }:
    let
      stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
      stableKanataBin = "${stableKanataDir}/kanata";
      stableKanataPackage = "${stableKanataDir}/package";

      stableKarabinerDir = "/usr/local/libexec/nix-darwin/karabiner";
      stableVhidApp = "${stableKarabinerDir}/Karabiner-VirtualHIDDevice-Daemon.app";
      stableVhidDaemon = "${stableVhidApp}/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

      realKanataBin = lib.getExe kanataWithCmd;

      karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";

      realVhidApp = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app";

      kanataDeviceWatcher = pkgs.writeShellScript "kanata-device-watcher" ''
        set -eu

        # The keyboards kanata sees, without its own virtual one. Fails when
        # kanata couldn't list them (its table's header is missing), so that
        # isn't taken for every keyboard being unplugged.
        device_snapshot() {
          list="$(${stableKanataBin} --list 2>/dev/null)" || return 1
          case $list in
            *"Available keyboard devices"*) ;;
            *) return 1 ;;
          esac
          printf '%s\n' "$list" \
            | /usr/bin/awk '/^0x/ && $0 !~ /Karabiner DriverKit VirtualHIDKeyboard/ { print }' \
            | /usr/bin/sort
        }

        # Let USB and the virtual HID driver settle, then make Kanata enumerate
        # once more. This closes the launch-at-boot device discovery race. Only
        # once a boot: launchd restarting the watcher shouldn't restart Kanata.
        boot="$(/usr/sbin/sysctl -n kern.boottime)"
        boot_file=/var/run/kanata-device-watcher.boot
        if [ "$(cat "$boot_file" 2>/dev/null)" != "$boot" ]; then
          /bin/sleep 5
          /bin/launchctl kickstart -k system/org.nixos.kanata || true
          printf '%s\n' "$boot" >"$boot_file"
          /bin/sleep 3
        fi

        until previous_devices="$(device_snapshot)"; do
          /bin/sleep 10
        done

        while /bin/sleep 10; do
          # Try again next time, comparing with the last list that worked.
          current_devices="$(device_snapshot)" || continue

          added_devices="$(
            /usr/bin/comm -13 \
              <(printf '%s\n' "$previous_devices") \
              <(printf '%s\n' "$current_devices")
          )"

          if [ -n "$added_devices" ]; then
            echo "Keyboard connected; restarting Kanata:"
            printf '%s\n' "$added_devices"
            /bin/launchctl kickstart -k system/org.nixos.kanata || true
          fi

          previous_devices="$current_devices"
        done
      '';
    in
    {
      system.activationScripts.preActivation.text = ''
        install -d -m 0755 ${stableKanataDir} ${stableKarabinerDir}

        # The copy is only replaced when the binary changes, so macOS keeps the
        # permissions it was given. Comparing the binary rather than the
        # version also catches a rebuild that keeps the version (a different
        # build option or patch). The GC root keeps the package it was copied
        # from, and so what the copy links to, alive. It's swapped in with mv,
        # so a restart never finds it missing, and Kanata is restarted to run
        # it (launchd only restarts it itself when its plist changes).
        if [ ! -x ${stableKanataBin} ] || [ ! -e ${stableKanataPackage} ] ||
          ! cmp -s ${realKanataBin} ${stableKanataBin}; then
          install -m 0755 ${realKanataBin} ${stableKanataBin}.new
          mv -f ${stableKanataBin}.new ${stableKanataBin}
          rm -f ${stableKanataPackage}
          ${pkgs.nix}/bin/nix-store --add-root ${stableKanataPackage} --indirect -r ${kanataWithCmd} >/dev/null
          /bin/launchctl kickstart -k system/org.nixos.kanata 2>/dev/null || true
        fi

        # The same for the virtual HID daemon, replaced when the package it's
        # copied from changes (source holds its path).
        if [ ! -d ${stableVhidApp} ] ||
          [ "$(cat ${stableKarabinerDir}/source 2>/dev/null)" != "${realVhidApp}" ]; then
          rm -rf ${stableVhidApp}.new
          # Never propagate macOS-managed metadata such as com.apple.macl into the
          # stable copy. If attached to an app in /nix/store, that attribute prevents
          # Nix from making the bundle writable during garbage collection.
          /usr/bin/ditto --norsrc --noqtn "${realVhidApp}" ${stableVhidApp}.new
          rm -rf ${stableVhidApp}
          mv ${stableVhidApp}.new ${stableVhidApp}
          printf '%s\n' "${realVhidApp}" >${stableKarabinerDir}/source
          /bin/launchctl kickstart -k system/org.nixos.karabiner-vhid 2>/dev/null || true
        fi
      '';

      system.activationScripts.postActivation.text = ''
        cat <<'EOF'

        Kanata permission note:

        If kanata does not work, macOS may be missing permissions.

        Open:
          System Settings → Privacy & Security → Input Monitoring
          System Settings → Privacy & Security → Accessibility

        Add/enable:
          ${stableKanataBin}

        Open:
          System Settings → General → Login Items & Extensions → Extensions

        Enable the driver extension:
          .Karabiner-VirtualHIDDevice-Manager

        EOF
      '';

      # nix-darwin puts karabinerManager, run below, in /Applications/Nix Apps.
      environment.systemPackages = [ pkgs.karabiner-dk ];

      launchd.user.agents.activate_karabiner_system_ext = {
        serviceConfig = {
          ProgramArguments = [
            karabinerManager
            "activate"
          ];
          RunAtLoad = true;
          StandardOutPath = "/tmp/karabiner-activate.out.log";
          StandardErrorPath = "/tmp/karabiner-activate.err.log";
        };
      };

      launchd.daemons.kanata = {
        serviceConfig = {
          ProgramArguments = [
            # Use a stable binary for stable accessibility and input monitoring permissions
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

      launchd.daemons.kanata-device-watcher = {
        serviceConfig = {
          ProgramArguments = [ "${kanataDeviceWatcher}" ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
          ThrottleInterval = 5;
          StandardOutPath = "/tmp/kanata-device-watcher.out.log";
          StandardErrorPath = "/tmp/kanata-device-watcher.err.log";
        };
      };

      launchd.daemons.karabiner-vhid = {
        serviceConfig = {
          Label = "org.nixos.karabiner-vhid";
          # Preserve the complete app bundle at a stable path so launchd never
          # retains an obsolete Nix store path. The shell wrapper is needed because
          # Nix packaging modifies the upstream code signature.
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''exec "$1"''
            "karabiner-vhid"
            stableVhidDaemon
          ];
          KeepAlive = true;
          RunAtLoad = true;
          ThrottleInterval = 5;
          StandardOutPath = "/tmp/karabiner-vhid.out.log";
          StandardErrorPath = "/tmp/karabiner-vhid.err.log";
        };
      };
    };
}
