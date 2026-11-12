# What a machine does for the others, from its features' settings.
rec {
  builds = features: features.fleet-builders.enable && features.fleet-builders.builder != null;
  # serves its store, signed, so only once it has its key (secrets/<hostname>.yaml)
  caches =
    features:
    features.fleet-substituters.enable
    && features.fleet-substituters.priority != null
    && features.secrets.active
    && features.fleet-substituters.publicKey != null;
  # the machines fleet-access is for
  servesFleet = features: builds features || caches features;
}
