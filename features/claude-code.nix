{ unstable, ... }:
{
  tags = [ "dev" ];
  unfree = [ "claude-code" ];
  packages = [ unstable.claude-code ];
}
