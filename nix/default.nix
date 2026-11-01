# Builds the configurations in flake.nix: NixOS and nix-darwin systems, which
# integrate Home Manager, and standalone Home Manager homes. A config passes the
# names of the modules it wants (see nix/modules.nix).
{ inputs }:
let
  inherit (inputs.nixpkgs-nixos) lib;
  catalog = import ./modules.nix { inherit lib; };
  inherit (import ./config.nix) username;

  isDarwin = lib.hasSuffix "-darwin";

  # What systems and homes build from, given the system and the module names.
  common = system: names: rec {
    selected = catalog.select names;
    homeDirectory = if isDarwin system then "/Users/${username}" else "/home/${username}";
    specialArgs = {
      inherit inputs username homeDirectory;
      repositoryPath = "${homeDirectory}/dotfiles";
    };
    packages = standalone: import ./packages.nix { inherit inputs selected standalone; };

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
      system,
      hostname,
      modules ? [ ],
    }:
    let
      c = common system modules;
      systemKey = if isDarwin system then "darwin" else "nixos";
      build =
        if isDarwin system then
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
        { nixpkgs.hostPlatform = system; }
        (c.packages false)
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
      system,
      modules ? [ ],
    }:
    let
      c = common system modules;
      nixpkgs = if isDarwin system then inputs.nixpkgs-darwin else inputs.nixpkgs-nixos;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = c.specialArgs;
      modules = [
        c.home
        # Standalone Home Manager owns nixpkgs; integrated homes use the system's.
        (c.packages true)
      ]
      ++ c.selected.home;
    };
}
