# What a machine does for the others, from its features' settings.
rec {
  builds = features: features.fleet-builders.enable && features.fleet-builders.builder != null;
  caches =
    features: features.fleet-substituters.enable && features.fleet-substituters.priority != null;
  # signs what it serves, once it has its key (secrets/<hostname>.yaml)
  signs =
    features:
    caches features && features.secrets.active && features.fleet-substituters.publicKey != null;
  # the machines fleet-access is for
  servesFleet = features: builds features || caches features;
}
