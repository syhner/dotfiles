{
  inputs,
  nixpkgs,
  username,
  repositoryPath,
  ...
}:

{
  system,
  # "system" | "home-manager"
  type ? "system",
  hostname ? null,
  cfg ? {
    defaultEnable = true;
  },
  extraSystemModules ? [ ],
  extraHomeModules ? [ ],
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

  specialArgs = {
    inherit
      inputs
      username
      hostname
      repositoryPath
      systemKey
      kernel
      cfg
      ;
  };

  inherit (nixpkgs.lib) optional;

  # load modules by default, unless cfg.enableModules is explicitly set to false
  defaultEnable = cfg.enableModules or true;

  homeManagerModules =
    extraHomeModules
    ++ optional (cfg.direnv.enable or defaultEnable) ./modules/direnv/home.nix
    ++ optional (cfg.git.enable or defaultEnable) ./modules/git/home.nix
    ++ optional (cfg.kanata.enable or defaultEnable) ./modules/kanata/home.nix
    ++ optional (cfg.linearmouse.enable or defaultEnable) ./modules/linearmouse/home.nix
    ++ optional (cfg.packages.enable or defaultEnable) ./modules/packages/home.nix
    ++ optional (cfg.zed.enable or defaultEnable) ./modules/zed/home.nix
    ++ optional (cfg.zsh.enable or defaultEnable) ./modules/zsh/home.nix;

  systemModules =
    extraSystemModules
    ++ optional (cfg.configuration.enable or defaultEnable) ./hosts/${hostname}/configuration.nix
    ++ optional (cfg.home-manager or defaultEnable) homeManagerSystemModuleConfiguration
    ++ optional (cfg.darwin.base.enable or defaultEnable) ./modules/darwin/base.nix
    ++ optional (cfg.git.enable or defaultEnable) ./modules/git/system.nix
    ++ optional (cfg.homebrew.enable or defaultEnable) ./modules/homebrew/system.nix
    ++ optional (cfg.kanata.enable or defaultEnable) ./modules/kanata/system.nix
    ++ optional (cfg.linearmouse.enable or defaultEnable) ./modules/linearmouse/system.nix
    ++ optional (cfg.nix.enable or defaultEnable) ./modules/nix/system.nix
    ++ optional (cfg.nix-index-database.enable or defaultEnable) ./modules/nix-index-database/system.nix
    ++ optional (cfg.nixos.base or defaultEnable) ./modules/nixos/base.nix
    ++ optional (cfg.nixos.graphical or defaultEnable) ./modules/nixos/graphical.nix
    ++ optional (cfg.packages.enable or defaultEnable) ./modules/packages/system.nix
    ++ optional (cfg.stylix.enable or defaultEnable) ./modules/stylix/system.nix
    ++ optional (cfg.zed.enable or defaultEnable) ./modules/zed/system.nix;

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
