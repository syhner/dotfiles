{
  inputs,
  username,
  systemKey,
  configDirectory,
  lib,
  config,
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

  # with this, can run `sudo cat /run/secrets/example_key`
  sops.secrets.example_key = { };

  # for `cat ${config.sops.secrets."my_service/my_subdir/my_secret".path}` to work
  sops.secrets."my_service/my_subdir/my_secret" = {
    owner = username;
  };

  # create /var/lib/sometestservice directory
  # system.activationScripts.preActivation.text = ''
  #   /usr/bin/install -d \
  #     -m 0750 \
  #     -o ${lib.escapeShellArg username} \
  #     -g staff \
  #     /var/lib/sometestservice
  # '';

  # launchd.daemons.sometestservice = {
  #   script = ''
  #     {
  #       echo "${config.sops.secrets."my_service/my_subdir/my_secret".path}"
  #       echo "contains"
  #       cat ${config.sops.secrets."my_service/my_subdir/my_secret".path}
  #     } > /var/lib/sometestservice/testfile
  #   '';

  #   serviceConfig = {
  #     UserName = username;
  #     WorkingDirectory = "/var/lib/sometestservice";
  #     RunAtLoad = true;
  #   };
  # };

}
