# Builds the configurations in flake.nix: NixOS and nix-darwin systems, which
# integrate Home Manager, and standalone Home Manager homes. A configuration
# passes the names of the modules it wants (see nix/modules.nix).
{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  inherit (import ./modules.nix { inherit lib; }) select;
  inherit (import ./config.nix) username;

  isDarwin = lib.hasSuffix "-darwin";

  # What systems and homes build from, given the platform and the module names.
  common = platform: modules: rec {
    selected = select modules;
    homeDirectory = if isDarwin platform then "/Users/${username}" else "/home/${username}";
    specialArgs = {
      inherit inputs username homeDirectory;
      repositoryPath = "${homeDirectory}/dotfiles";
    };

    # Every home, integrated or standalone.
    home = {
      home.username = username;
      home.homeDirectory = homeDirectory;

      # The Home Manager release this configuration is compatible with. Read the
      # Home Manager release notes before changing it.
      home.stateVersion = "26.05";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
  };
in
{
  inherit isDarwin;

  mkSystem =
    {
      platform,
      hostname,
      modules ? [ ],
    }:
    let
      c = common platform modules;
      systemKey = if isDarwin platform then "darwin" else "nixos";
      build =
        if isDarwin platform then
          inputs.nix-darwin.lib.darwinSystem
        else
          inputs.nixpkgs-nixos.lib.nixosSystem;
    in
    build {
      specialArgs = c.specialArgs // {
        inherit hostname systemKey;
      };
      modules = [
        ../hosts/${hostname}/configuration.nix
        { nixpkgs.hostPlatform = platform; }
        (import ./packages.nix {
          inherit inputs;
          inherit (c) selected;
          standalone = false;
        })
        {
          imports = [ inputs.home-manager."${systemKey}Modules".home-manager ];
          # Home Manager reads the home directory from here.
          users.users.${username}.home = c.homeDirectory;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = c.specialArgs;
          home-manager.users.${username}.imports = [ c.home ] ++ c.selected.home;
        }
      ]
      ++ c.selected.system;
    };

  mkHome =
    {
      platform,
      modules ? [ ],
    }:
    let
      c = common platform modules;
      nixpkgs = if isDarwin platform then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${platform};
      extraSpecialArgs = c.specialArgs;
      modules = [
        c.home
        # Standalone Home Manager owns nixpkgs; integrated homes use the system's.
        (import ./packages.nix {
          inherit inputs;
          inherit (c) selected;
          standalone = true;
        })
      ]
      ++ c.selected.home;
    };
}
