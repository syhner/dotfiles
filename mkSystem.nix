{
  inputs,
  system,
  # "system" | "home-manager"
  type ? "system",
  hostname ? null,
  defaultModuleBehaviour ? true,
  cfg ? { },
  extraHomeModules ? [ ],
  extraSystemModules ? [ ],
}:
let
  username = import ./config/username.nix;

  isLinux = inputs.nixpkgs.lib.hasSuffix "-linux" system;
  isDarwin = inputs.nixpkgs.lib.hasSuffix "-darwin" system;

  systemKey =
    if type == "home-manager" then
      "home"
    else if isDarwin then
      "darwin"
    else
      "nixos";

  nixpkgs = if isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs;
  homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
  configDirectory =
    if isDarwin then "${homeDirectory}/Library/Application Support" else "${homeDirectory}/.config";
  repositoryPath = "${homeDirectory}/dotfiles";

  # Each setting uses its override when supplied, otherwise its default.
  moduleConfig = {
    modules.home = cfg.modules.home or defaultModuleBehaviour;
    modules.system = cfg.modules.system or defaultModuleBehaviour;

    configuration = cfg.configuration or defaultModuleBehaviour;
    home-manager = cfg.home-manager or defaultModuleBehaviour;
    darwin.base = cfg.darwin.base or isDarwin;
    deskflow = cfg.deskflow or isDarwin;
    direnv = cfg.direnv or defaultModuleBehaviour;
    git = cfg.git or defaultModuleBehaviour;
    gpg = cfg.gpg or defaultModuleBehaviour;
    ghostty = cfg.ghostty or defaultModuleBehaviour;
    homebrew = cfg.homebrew or isDarwin;
    kanata = cfg.kanata or isDarwin;
    linearmouse = cfg.linearmouse or isDarwin;
    newsboat = cfg.newsboat or defaultModuleBehaviour;
    nix = cfg.nix or defaultModuleBehaviour;
    nix-index-database =
      cfg.nix-index-database or (
        defaultModuleBehaviour
        && builtins.elem system [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ]
      );
    nixos.avahi = cfg.nixos.avahi or isLinux;
    nixos.base = cfg.nixos.base or isLinux;
    nixos.graphical = cfg.nixos.graphical or false;
    nixos.init = cfg.nixos.init or isLinux;
    nixos.share = cfg.nixos.share or false;
    nixos.ssh = cfg.nixos.ssh or isLinux;
    nixos.systemd-boot = cfg.nixos.systemd-boot or isLinux;
    nixos.tailscale = cfg.nixos.tailscale or isLinux;
    packages = cfg.packages or defaultModuleBehaviour;
    qbittorrent = cfg.qbittorrent or isDarwin;
    sops = cfg.sops or defaultModuleBehaviour;
    stylix = cfg.stylix or defaultModuleBehaviour;
    thunderbird = cfg.thunderbird or defaultModuleBehaviour;
    tmux = cfg.tmux or defaultModuleBehaviour;
    zed = cfg.zed or isDarwin;
    zsh = cfg.zsh or defaultModuleBehaviour;

    package.proton-vpn = cfg.package.proton-vpn or true;
    package.obsidian = cfg.package.obsidian or true;
    package.spotify = cfg.package.spotify or true;
    package.opencode = cfg.package.opencode or true;
    package.nil = cfg.package.nil or true;
    package.nixd = cfg.package.nixd or true;
    package.nerd-fonts = cfg.package.nerd-fonts or true;
  };

  specialArgs = {
    cfg = moduleConfig;
    inherit
      inputs
      username
      hostname
      homeDirectory
      configDirectory
      repositoryPath
      systemKey
      isLinux
      isDarwin
      type
      ;
  };

  inherit (nixpkgs.lib) optional optionals;

  homeModules =
    extraHomeModules
    ++ optionals moduleConfig.modules.home (
      optional moduleConfig.deskflow ./modules/deskflow/home.nix
      ++ optional moduleConfig.direnv ./modules/direnv/home.nix
      ++ optional moduleConfig.git ./modules/git/home.nix
      ++ optional moduleConfig.gpg ./modules/gpg/home.nix
      ++ optional moduleConfig.ghostty ./modules/ghostty/home.nix
      ++ optional moduleConfig.kanata ./modules/kanata/home.nix
      ++ optional moduleConfig.linearmouse ./modules/linearmouse/home.nix
      ++ optional moduleConfig.newsboat ./modules/newsboat/home.nix
      ++ optional moduleConfig.packages ./modules/packages/home.nix
      ++ optional moduleConfig.tmux ./modules/tmux/home.nix
      ++ optional moduleConfig.zed ./modules/zed/home.nix
      ++ optional moduleConfig.zsh ./modules/zsh/home.nix
    );

  systemModules =
    extraSystemModules
    ++ optionals moduleConfig.modules.system (
      optional moduleConfig.configuration ./hosts/${hostname}/configuration.nix
      ++ optional moduleConfig.home-manager homeManagerModule
      ++ optional moduleConfig.darwin.base ./modules/darwin/base.nix
      ++ optional moduleConfig.deskflow ./modules/deskflow/system.nix
      ++ optional moduleConfig.homebrew ./modules/homebrew/system.nix
      ++ optional moduleConfig.kanata ./modules/kanata/system.nix
      ++ optional moduleConfig.nix ./modules/nix/system.nix
      ++ optional moduleConfig.nix-index-database ./modules/nix-index-database/system.nix
      ++ optional moduleConfig.nixos.avahi ./modules/nixos/avahi.nix
      ++ optional moduleConfig.nixos.base ./modules/nixos/base.nix
      ++ optional moduleConfig.nixos.graphical ./modules/nixos/graphical.nix
      ++ optional moduleConfig.nixos.init ./modules/nixos/init.nix
      ++ optional moduleConfig.nixos.share ./modules/nixos/share.nix
      ++ optional moduleConfig.nixos.ssh ./modules/nixos/ssh.nix
      ++ optional moduleConfig.nixos.systemd-boot ./modules/nixos/systemd-boot.nix
      ++ optional moduleConfig.nixos.tailscale ./modules/nixos/tailscale.nix
      ++ optional moduleConfig.packages ./modules/packages/system.nix
      ++ optional moduleConfig.sops ./modules/sops/system.nix
      ++ optional moduleConfig.stylix ./modules/stylix/system.nix
    );

  homeManagerModule = {
    imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${username} = {
      imports = [ ./home.nix ] ++ homeModules;
    };
  };

  systemArgs = {
    inherit system specialArgs;
    modules = systemModules;
  };
in
if !(isLinux || isDarwin) then
  throw "unsupported system: ${system}"
else if type == "home-manager" then
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.${system};
    extraSpecialArgs = specialArgs;
    modules = [ ./home.nix ] ++ homeModules;
  }
else if type != "system" then
  throw "unsupported configuration: ${type}"
else if isDarwin then
  inputs.nix-darwin.lib.darwinSystem systemArgs
else
  nixpkgs.lib.nixosSystem systemArgs
