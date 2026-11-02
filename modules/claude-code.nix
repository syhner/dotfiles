{
  tags = [ "workstation" ];
  unfree = [ "claude-code" ];
  packages = pkgs: [ pkgs.unstable.claude-code ];
}
