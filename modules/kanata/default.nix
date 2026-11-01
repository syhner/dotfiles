{
  home = ./home.nix;
  system = ./system.nix;
  packages = pkgs: [
    (import ./package.nix pkgs)
    # Installed system-wide, nix-darwin puts the Karabiner manager that
    # system.nix runs in /Applications/Nix Apps.
    pkgs.karabiner-dk
  ];
}
