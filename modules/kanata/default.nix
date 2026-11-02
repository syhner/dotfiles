let
  # Allowed to run shell commands.
  kanata = pkgs: pkgs.kanata.override { withCmd = true; };
in
{
  tags = [ "darwin" ];

  packages = pkgs: [
    (kanata pkgs)
    # nix-darwin puts the Karabiner manager that the system part runs in
    # /Applications/Nix Apps.
    pkgs.karabiner-dk
  ];

  home =
    {
      config,
      repositoryPath,
      ...
    }:
    {
      home.file.".config/kanata/kanata.kbd".source =
        config.lib.file.mkOutOfStoreSymlink "${repositoryPath}/modules/kanata/kanata.kbd";
    };

  system = import ./system.nix kanata;
}
