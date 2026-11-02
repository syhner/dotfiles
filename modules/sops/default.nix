{
  tags = [ "base" ];
  packages = pkgs: [ pkgs.sops ];

  home =
    {
      config,
      inputs,
      lib,
      pkgs,
      standalone,
      ...
    }:
    # Does the system part's job when Home Manager runs standalone.
    lib.optionalAttrs standalone {
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
    };

  system =
    {
      inputs,
      systemKey,
      ...
    }:

    {
      imports = [ inputs.sops-nix."${systemKey}Modules".sops ];
      sops.defaultSopsFile = ./secrets.yaml;

      # with this, can run `sudo cat /run/secrets/example_key`
      # sops.secrets.example_key = { };

      # for `cat ${config.sops.secrets."my_service/my_subdir/my_secret".path}` to work
      # sops.secrets."my_service/my_subdir/my_secret" = {
      #   owner = username;
      # };

      # # create /var/lib/sometestservice directory
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

    };
}
