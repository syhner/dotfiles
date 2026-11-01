# Every module a config can opt into, and the sets of them that describe what a
# machine is. A config gets nothing it doesn't ask for.
#
# A module has a home part, a system part, both, or neither. Modules with
# neither only add packages (see modules/packages/packages.nix), so they need
# the packages module too.
let
  all = {
    avahi.system = ../modules/nixos/avahi.nix;
    darwin.system = ../modules/darwin/base.nix;
    deskflow = {
      home = ../modules/deskflow/home.nix;
      system = ../modules/deskflow/system.nix;
    };
    direnv.home = ../modules/direnv/home.nix;
    ghostty.home = ../modules/ghostty/home.nix;
    git.home = ../modules/git/home.nix;
    gpg.home = ../modules/gpg/home.nix;
    graphical.system = ../modules/nixos/graphical.nix;
    grandperspective = { };
    homebrew.system = ../modules/homebrew/system.nix;
    kanata = {
      home = ../modules/kanata/home.nix;
      system = ../modules/kanata/system.nix;
    };
    linearmouse.home = ../modules/linearmouse/home.nix;
    nerd-fonts = { };
    newsboat.home = ../modules/newsboat/home.nix;
    nil = { };
    nix.system = ../modules/nix/system.nix;
    # No prebuilt database for x86_64-darwin.
    nix-index-database.system = ../modules/nix-index-database/system.nix;
    nixd = { };
    nixos.system = [
      ../modules/nixos/base.nix
      ../modules/nixos/init.nix
    ];
    obsidian = { };
    opencode = { };
    packages = {
      home = ../modules/packages/home.nix;
      system = ../modules/packages/system.nix;
    };
    proton-vpn = { };
    qbittorrent = { };
    share.system = ../modules/nixos/share.nix;
    sops.system = ../modules/sops/system.nix;
    spotify = { };
    ssh.system = ../modules/nixos/ssh.nix;
    stylix.system = ../modules/stylix/system.nix;
    systemd-boot.system = ../modules/nixos/systemd-boot.nix;
    tailscale.system = ../modules/nixos/tailscale.nix;
    thunderbird = { };
    tmux.home = ../modules/tmux/home.nix;
    utm = { };
    zed.home = ../modules/zed/home.nix;
    zsh.home = ../modules/zsh/home.nix;
  };

  # Plain lists of module names, so configs combine them with ++.
  sets = {
    # Every machine.
    base = [
      "direnv"
      "git"
      "gpg"
      "newsboat"
      "nix"
      "packages"
      "sops"
      "stylix"
      "tmux"
      "zsh"
    ];

    # A machine I sit at and work on, rather than a server.
    workstation = [
      "ghostty"
      "nerd-fonts"
      "nil"
      "nix-index-database"
      "nixd"
      "obsidian"
      "opencode"
      "proton-vpn"
      "spotify"
      "thunderbird"
    ];

    # A Mac.
    mac = [
      "darwin"
      "deskflow"
      "grandperspective"
      "homebrew"
      "kanata"
      "linearmouse"
      "qbittorrent"
      "utm"
      "zed"
    ];

    # A NixOS VM running in UTM on the Mac.
    utm-vm = [
      "avahi"
      "nixos"
      "share"
      "ssh"
      "systemd-boot"
      "tailscale"
    ];
  };

in
{
  inherit sets;

  select =
    names:
    let
      unknown = builtins.filter (name: !(all ? ${name})) names;
      enabled = builtins.mapAttrs (name: _: builtins.elem name names) all;

      # Modules load in the order above, whatever order a config lists them in.
      selected = builtins.filter (module: enabled.${module}) (builtins.attrNames all);
      partOf =
        part:
        builtins.concatMap (
          name:
          let
            files = all.${name}.${part} or [ ];
          in
          if builtins.isList files then files else [ files ]
        ) selected;
    in
    if unknown != [ ] then
      throw "unknown modules: ${toString unknown}"
    else
      {
        inherit enabled;
        home = partOf "home";
        system = partOf "system";
      };
}
