# Kanata, allowed to run shell commands. Shared by default.nix, which installs
# it, and system.nix, which runs it as the daemon, so both use the same build.
pkgs: pkgs.kanata.override { withCmd = true; }
