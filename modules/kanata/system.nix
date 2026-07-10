{
  pkgs,
  lib,
  username,
  ...
}:
let
  stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
  stableKanataBin = "${stableKanataDir}/kanata";

  realKanataBin = lib.getExe pkgs.kanata;

  karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";

  realVhidDaemon = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
in
{
  system.activationScripts.preActivation.text = ''
    install -d -m 0755 ${stableKanataDir}
    rm -f ${stableKanataBin}
    install -m 0755 ${realKanataBin} ${stableKanataBin}
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
      Label = "org.nixos.karabiner-vhid";
      # launchd rejects the daemon from the Nix store as a missing executable
      # because the package's upstream code signature is no longer valid.
      # Starting it through Apple's signed shell works like invoking it with
      # sudo in a terminal, while keeping the executable in its app bundle.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''exec "$1"''
        "karabiner-vhid"
        realVhidDaemon
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 5;
      StandardOutPath = "/tmp/karabiner-vhid.out.log";
      StandardErrorPath = "/tmp/karabiner-vhid.err.log";
    };
  };
}
