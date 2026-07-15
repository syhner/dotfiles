{
  inputs,
  nixpkgs,
  username,
  ...
}:

{
  system,
  # "system" | "home-manager"
  type ? "system",
  hostname ? null,
  defaultModuleBehaviour ? true,
  cfg ? { },
  extraHomeModules ? [ ],
  extraSystemModules ? [ ],
  ...
}:

let
  systemKey =
    if type == "home-manager" then
      "home"
    else if system == "x86_64-linux" || system == "aarch64-linux" then
      "nixos"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  mkSystem =
    {
      darwin = inputs.nix-darwin.lib.darwinSystem;
      nixos = nixpkgs.lib.nixosSystem;
      home = inputs.home-manager.lib.homeManagerConfiguration;
    }
    .${systemKey};

  kernel =
    if system == "x86_64-linux" || system == "aarch64-linux" then
      "linux"
    else if system == "x86_64-darwin" || system == "aarch64-darwin" then
      "darwin"
    else
      throw "unsupported system: ${system}";

  homeDirectory =
    if kernel == "linux" then
      "/home/${username}"
    else if kernel == "darwin" then
      "/Users/${username}"
    else
      throw "unsupported kernel: ${kernel}";

  configDirectory =
    if kernel == "linux" then
      "${homeDirectory}/.config"
    else if kernel == "darwin" then
      "${homeDirectory}/Library/Application Support"
    else
      throw "unsupported kernel: ${kernel}";

  repositoryPath = "${homeDirectory}/dotfiles";
in

(
  cfg:
  let
    specialArgs = {
      inherit
        inputs
        username
        hostname
        homeDirectory
        configDirectory
        repositoryPath
        systemKey
        kernel
        type
        cfg
        ;
    };

    inherit (nixpkgs.lib) optional optionals;

    homeModules =
      extraHomeModules
      ++ optionals cfg.modules.home (
        optional cfg.direnv ./modules/direnv/home.nix
        ++ optional cfg.git ./modules/git/home.nix
        ++ optional cfg.ghostty ./modules/ghostty/home.nix
        ++ optional cfg.kanata ./modules/kanata/home.nix
        ++ optional cfg.linearmouse ./modules/linearmouse/home.nix
        ++ optional cfg.packages ./modules/packages/home.nix
        ++ optional cfg.zed ./modules/zed/home.nix
        ++ optional cfg.zsh ./modules/zsh/home.nix
      );

    systemModules =
      extraSystemModules
      ++ optionals cfg.modules.system (
        optional cfg.configuration ./hosts/${hostname}/configuration.nix
        ++ optional cfg.home-manager homeManagerSystemModuleConfiguration
        ++ optional cfg.darwin.base ./modules/darwin/base.nix
        ++ optional cfg.homebrew ./modules/homebrew/system.nix
        ++ optional cfg.kanata ./modules/kanata/system.nix
        ++ optional cfg.nix ./modules/nix/system.nix
        ++ optional cfg.nix-index-database ./modules/nix-index-database/system.nix
        ++ optional cfg.nixos.avahi ./modules/nixos/avahi.nix
        ++ optional cfg.nixos.base ./modules/nixos/base.nix
        ++ optional cfg.nixos.graphical ./modules/nixos/graphical.nix
        ++ optional cfg.nixos.init ./modules/nixos/init.nix
        ++ optional cfg.nixos.share ./modules/nixos/share.nix
        ++ optional cfg.nixos.ssh ./modules/nixos/ssh.nix
        ++ optional cfg.nixos.tailscale ./modules/nixos/tailscale.nix
        ++ optional cfg.packages ./modules/packages/system.nix
        ++ optional cfg.sops ./modules/sops/system.nix
        ++ optional cfg.stylix ./modules/stylix/system.nix
      );

    homeManagerSystemModuleConfiguration = {
      imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.users.${username} = {
        imports = [ ./home.nix ] ++ homeModules;
      };
    };
  in

  if type == "system" then
    mkSystem {
      inherit system specialArgs;
      modules = systemModules;
    }
  else if type == "home-manager" then
    mkSystem {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = specialArgs;
      modules = [ ./home.nix ] ++ homeModules;
    }
  else
    throw "unsupported configuration"
)
  # default cfg
  {
    modules.home = cfg.modules.home or defaultModuleBehaviour;
    modules.system = cfg.modules.system or defaultModuleBehaviour;

    configuration = cfg.configuration or defaultModuleBehaviour;
    home-manager = cfg.home-manager or defaultModuleBehaviour;
    darwin.base = cfg.darwin.base or (kernel == "darwin");
    direnv = cfg.direnv or defaultModuleBehaviour;
    git = cfg.git or defaultModuleBehaviour;
    ghostty = cfg.ghostty or defaultModuleBehaviour;
    homebrew = cfg.homebrew or (kernel == "darwin");
    kanata = cfg.kanata or (kernel == "darwin");
    linearmouse = cfg.linearmouse or (kernel == "darwin");
    nix = cfg.nix or defaultModuleBehaviour;
    nix-index-database = cfg.nix-index-database or defaultModuleBehaviour;
    nixos.avahi = cfg.nixos.avahi or (kernel == "linux");
    nixos.base = cfg.nixos.base or (kernel == "linux");
    nixos.graphical = cfg.nixos.graphical or false;
    nixos.init = cfg.nixos.init or (kernel == "linux");
    nixos.share = cfg.nixos.share or false;
    nixos.ssh = cfg.nixos.ssh or (kernel == "linux");
    nixos.systemd-boot = cfg.nixos.systemd-boot or (kernel == "linux");
    nixos.tailscale = cfg.nixos.tailscale or (kernel == "linux");
    packages = cfg.packages or defaultModuleBehaviour;
    sops = cfg.sops or defaultModuleBehaviour;
    stylix = cfg.stylix or defaultModuleBehaviour;
    zed = cfg.zed or (kernel == "darwin");
    zsh = cfg.zsh or defaultModuleBehaviour;

    package.proton-vpn = cfg.package.proton-vpn or true;
    package.obsidian = cfg.package.obsidian or true;
    package.spotify = cfg.package.spotify or true;
    package.opencode = cfg.package.opencode or true;
    package.nil = cfg.package.nil or true;
    package.nixd = cfg.package.nixd or true;
    package.nerd-fonts = cfg.package.nerd-fonts or true;
  }
