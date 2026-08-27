{
  pkgs,
  lib,
  username,
  ...
}:
let
  stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
  stableKanataBin = "${stableKanataDir}/kanata";
  stableKanataPackage = "${stableKanataDir}/package";

  stableKarabinerDir = "/usr/local/libexec/nix-darwin/karabiner";
  stableVhidApp = "${stableKarabinerDir}/Karabiner-VirtualHIDDevice-Daemon.app";
  stableVhidDaemon = "${stableVhidApp}/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

  realKanataBin = lib.getExe pkgs.kanata;

  karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";

  realVhidApp = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app";

  kanataDeviceWatcher = pkgs.writeShellScript "kanata-device-watcher" ''
    set -eu

    device_snapshot() {
      ${stableKanataBin} --list 2>/dev/null \
        | /usr/bin/awk '/^0x/ && $0 !~ /Karabiner DriverKit VirtualHIDKeyboard/ { print }' \
        | /usr/bin/sort
    }

    # Let USB and the virtual HID driver settle, then make Kanata enumerate
    # once more. This closes the launch-at-boot device discovery race.
    /bin/sleep 5
    /bin/launchctl kickstart -k system/org.nixos.kanata || true
    /bin/sleep 3

    previous_devices="$(device_snapshot)"

    while /bin/sleep 10; do
      current_devices="$(device_snapshot)"

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

    new_kanata_version="$(${realKanataBin} --version)"
    old_kanata_version="$(${stableKanataBin} --version 2>/dev/null || true)"
    install_kanata=no

    if [ ! -x ${stableKanataBin} ] || [ "$old_kanata_version" != "$new_kanata_version" ]; then
      install_kanata=yes
    elif [ ! -e ${stableKanataPackage} ] && ! cmp -s ${realKanataBin} ${stableKanataBin}; then
      # Migrate installations created before the package GC root existed.
      install_kanata=yes
    fi

    if [ "$install_kanata" = yes ]; then
      rm -f ${stableKanataBin} ${stableKanataPackage}
      install -m 0755 ${realKanataBin} ${stableKanataBin}
      ${pkgs.nix}/bin/nix-store --add-root ${stableKanataPackage} --indirect -r ${pkgs.kanata} >/dev/null
    elif [ ! -e ${stableKanataPackage} ]; then
      rm -f ${stableKanataPackage}
      ${pkgs.nix}/bin/nix-store --add-root ${stableKanataPackage} --indirect -r ${pkgs.kanata} >/dev/null
    fi

    rm -rf ${stableVhidApp}
    /usr/bin/ditto "${realVhidApp}" ${stableVhidApp}
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
        "/Users/${username}/.config/kanata/kanata.kbd"
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
}
