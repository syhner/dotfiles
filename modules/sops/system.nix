{
  inputs,
  username,
  systemKey,
  configDirectory,
  ...
}:

{
  imports = [
    (
      {
        nixos = inputs.sops-nix.nixosModules.sops;
        darwin = inputs.sops-nix.darwinModules.sops;
        home = inputs.sops-nix.homeManagerModules.sops;
      }
      .${systemKey}
    )
  ];
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "${configDirectory}/sops/age/keys.txt";

  # with this, can run `sudo cat /run/secrets/example_key` or access `config.sops.secrets.example_key` in nix
  sops.secrets.example_key = { };

  sops.secrets."my_service/my_subdir/my_secret" = {
    owner = username;
  };

  # system.activationScripts.preActivation.text = ''
  #   man  -d \
  #     -m 0750 \
  #     -o ${lib.escapeShellArg username} \
  #     -g staff \
  #     /var/lib/sometestservice
  # '';

  # launchd.daemons.sometestservice = {
  #   script = ''
  #     {
  #       echo "Hey bro! I'm a service, and imma send this secure password:"
  #       cat ${config.sops.secrets."my_service/my_subdir/my_secret".path}
  #       echo "located in:"
  #       echo ${config.sops.secrets."my_service/my_subdir/my_secret".path}
  #       echo "to database and hack the mainframe"
  #     } > /var/lib/sometestservice/testfile
  #   '';

  #   serviceConfig = {
  #     UserName = username;
  #     WorkingDirectory = "/var/lib/sometestservice";
  #     RunAtLoad = true;
  #   };
  # };

}
