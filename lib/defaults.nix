{
  system,
  isLinux,
  isDarwin,
  defaultModuleBehaviour,
  features ? { },
}:
# Each setting uses its override when supplied, otherwise its default.
{
  modules.home = features.modules.home or defaultModuleBehaviour;
  modules.system = features.modules.system or defaultModuleBehaviour;

  configuration = features.configuration or defaultModuleBehaviour;
  home-manager = features.home-manager or defaultModuleBehaviour;
  darwin.base = features.darwin.base or isDarwin;
  deskflow = features.deskflow or isDarwin;
  direnv = features.direnv or defaultModuleBehaviour;
  git = features.git or defaultModuleBehaviour;
  gpg = features.gpg or defaultModuleBehaviour;
  ghostty = features.ghostty or defaultModuleBehaviour;
  homebrew = features.homebrew or isDarwin;
  kanata = features.kanata or isDarwin;
  linearmouse = features.linearmouse or isDarwin;
  newsboat = features.newsboat or defaultModuleBehaviour;
  nix = features.nix or defaultModuleBehaviour;
  nix-index-database =
    features.nix-index-database or (
      defaultModuleBehaviour
      && builtins.elem system [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ]
    );
  nixos.avahi = features.nixos.avahi or isLinux;
  nixos.base = features.nixos.base or isLinux;
  nixos.graphical = features.nixos.graphical or false;
  nixos.init = features.nixos.init or isLinux;
  nixos.share = features.nixos.share or false;
  nixos.ssh = features.nixos.ssh or isLinux;
  nixos.systemd-boot = features.nixos.systemd-boot or isLinux;
  nixos.tailscale = features.nixos.tailscale or isLinux;
  packages = features.packages or defaultModuleBehaviour;
  qbittorrent = features.qbittorrent or isDarwin;
  sops = features.sops or defaultModuleBehaviour;
  stylix = features.stylix or defaultModuleBehaviour;
  thunderbird = features.thunderbird or defaultModuleBehaviour;
  tmux = features.tmux or defaultModuleBehaviour;
  zed = features.zed or isDarwin;
  zsh = features.zsh or defaultModuleBehaviour;

  package.proton-vpn = features.package.proton-vpn or true;
  package.obsidian = features.package.obsidian or true;
  package.spotify = features.package.spotify or true;
  package.opencode = features.package.opencode or true;
  package.nil = features.package.nil or true;
  package.nixd = features.package.nixd or true;
  package.nerd-fonts = features.package.nerd-fonts or true;
}
