{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.sops-nix.homeModules.sops ];
  sops.defaultSopsFile = ./secrets.yaml;

  # Where the sops CLI looks for the age key (see .sops.yaml).
  sops.age.keyFile =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/age/keys.txt"
    else
      "${config.xdg.configHome}/age/keys.txt";

  # with this, `cat ${config.sops.secrets.example_key.path}` works
  # sops.secrets.example_key = { };
}
