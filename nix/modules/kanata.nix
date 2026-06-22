{
  pkgs,
  lib,
  ...
}:
let
  stableKanataDir = "/usr/local/libexec/nix-darwin/kanata";
  stableKanataBin = "${stableKanataDir}/kanata";
  karabinerManager = "/Applications/Nix Apps/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";
  karabinerVhidDaemon = "${pkgs.karabiner-dk}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
in
{
  system.activationScripts.preActivation.text = ''
    mkdir -p ${stableKanataDir}
    install -m 0755 ${lib.getExe pkgs.kanata} ${stableKanataBin}
  '';

  system.activationScripts.postActivation.text = ''
    cat <<'EOF'

    Kanata permission note:

    If kanata does not work, macOS may be missing permissions.

    Open:
      System Settings → Privacy & Security → Input Monitoring
      System Settings → Privacy & Security → Accessibility

    Add/enable:
      /usr/local/libexec/nix-darwin/kanata/kanata

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
        "/Users/siraj/.config/kanata/kanata.kbd"
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
      ProgramArguments = [ karabinerVhidDaemon ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/karabiner-vhid.out.log";
      StandardErrorPath = "/tmp/karabiner-vhid.err.log";
    };
  };
}
