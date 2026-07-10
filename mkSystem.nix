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
  cfgOverrides ? { },
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

  repositoryPath =
    if kernel == "linux" then
      "/home/${username}/dotfiles"
    else if kernel == "darwin" then
      "/Users/${username}/dotfiles"
    else
      throw "unsupported kernel: ${kernel}";

  specialArgs = {
    inherit
      inputs
      username
      hostname
      repositoryPath
      systemKey
      kernel
      cfg
      type
      ;
  };

  inherit (nixpkgs.lib) optional;

  # set cfg defaults with access to local variables
  cfgDefaults = {
    modules.home = true;
    modules.system = true;

    configuration = true;
    home-manager = true;
    darwin.base = (kernel == "darwin");
    direnv = true;
    git = true;
    homebrew = (kernel == "darwin");
    kanata = (kernel == "darwin");
    linearmouse = (kernel == "darwin");
    nix = true;
    nix-index-database = true;
    nixos.base = (kernel == "linux");
    nixos.graphical = (kernel == "linux");
    packages = true;
    stylix = true;
    zed = true;
    zsh = true;
  };

  cfg = nixpkgs.lib.recursiveUpdate cfgDefaults cfgOverrides;

  homeManagerModules =
    if cfg.modules.home then
      extraHomeModules
      ++ optional cfg.direnv ./modules/direnv/home.nix
      ++ optional cfg.git ./modules/git/home.nix
      ++ optional cfg.kanata ./modules/kanata/home.nix
      ++ optional cfg.linearmouse ./modules/linearmouse/home.nix
      ++ optional cfg.packages ./modules/packages/home.nix
      ++ optional cfg.zed ./modules/zed/home.nix
      ++ optional cfg.zsh ./modules/zsh/home.nix
    else
      [ ];

  systemModules =
    if cfg.modules.system then
      extraSystemModules
      ++ optional cfg.configuration ./hosts/${hostname}/configuration.nix
      ++ optional cfg.home-manager homeManagerSystemModuleConfiguration
      ++ optional cfg.darwin.base ./modules/darwin/base.nix
      ++ optional cfg.homebrew ./modules/homebrew/system.nix
      ++ optional cfg.kanata ./modules/kanata/system.nix
      ++ optional cfg.nix ./modules/nix/system.nix
      ++ optional cfg.nix-index-database ./modules/nix-index-database/system.nix
      ++ optional cfg.nixos.base ./modules/nixos/base.nix
      ++ optional cfg.nixos.graphical ./modules/nixos/graphical.nix
      ++ optional cfg.packages ./modules/packages/system.nix
      ++ optional cfg.stylix ./modules/stylix/system.nix
    else
      [ ];

  homeManagerSystemModuleConfiguration = {
    imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${username} = {
      imports = [ ./home.nix ] ++ homeManagerModules;
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
    modules = [ ./home.nix ] ++ homeManagerModules;
  }
else
  throw "unsupported configuration"
