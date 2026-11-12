{
  config,
  lib,
  unstable,
  ...
}:
{
  config = lib.mkIf config.features.claude-code.enable {
    unfree = [ "claude-code" ];
    packages = [ unstable.claude-code ];
  };
}
