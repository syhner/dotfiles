{
  machine,
  pkgs,
  settings,
  ...
}:
{
  tags = [ "github-runner" ];

  system.services.github-runners.${machine.hostname} = {
    enable = true;
    url = "https://github.com/${settings.repository}";
    tokenFile = "/var/lib/github-runner.token";
    extraLabels = [ machine.hostname ];
    replace = true;
    extraPackages = with pkgs; [
      cachix
      findutils
      gawk
      getconf
      gnugrep
      gnused
      jq
    ];
  };
}
