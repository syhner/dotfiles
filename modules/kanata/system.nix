{
  pkgs,
  lib,
  username,
  platform,
  ...
}:
let
  stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
  stableKanataBin = "${stableKanataDir}/kanata";

  realKanataBin = lib.getExe pkgs.kanata;

  karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";

  # karabinerVhidDaemon = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

  stableKarabinerDir = "/usr/local/libexec/nix-darwin/karabiner";
  stableVhidDaemon = "${stableKarabinerDir}/Karabiner-VirtualHIDDevice-Daemon";
  realVhidDaemon = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
in
if (platform == "darwin") then
  {
    environment.systemPackages = [
      pkgs.kanata
      # Karabiner-VirtualHIDDevice driver for kanata
      pkgs.karabiner-dk
    ];

    system.activationScripts.preActivation.text = ''
      install -d -m 0755 ${stableKanataDir} ${stableKarabinerDir}
      rm -f ${stableKanataBin} ${stableVhidDaemon}
      install -m 0755 ${realKanataBin} ${stableKanataBin}
      install -m 0755 "${realVhidDaemon}" ${stableVhidDaemon}
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

    launchd.daemons.karabiner-vhid = {
      serviceConfig = {
        Label = "org.pqrs.Karabiner-VirtualHIDDevice-Daemon";
        ProgramArguments = [ stableVhidDaemon ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/karabiner-vhid.out.log";
        StandardErrorPath = "/tmp/karabiner-vhid.err.log";
      };
    };
  }
else
  { }
