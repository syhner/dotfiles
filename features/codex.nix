{
  config,
  lib,
  unstable,
  ...
}:
{
  config = lib.mkIf config.features.codex.enable {
    packages = [ unstable.codex ];
  };
}
