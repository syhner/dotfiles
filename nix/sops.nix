# .sops.yaml: who sops encrypts each file in secrets/ for, and recipients: who
# each file is encrypted for once sops updatekeys has run. The checks fail when
# either is out of date; nix build .#sops-config makes .sops.yaml.
{
  lib,
  machines,
  settings,
}:
let
  # with secrets, so with an age key
  withKeys = builtins.filter (machine: machine.features.secrets.active) machines;
  hostnames = map (machine: machine.hostname) withKeys;

  # each key once, as an anchor the rules refer to
  aliases = names: "[ ${lib.concatMapStringsSep ", " (name: "*${name}") names} ]";

  rule =
    regex: ageKeys:
    [
      "  - path_regex: ${regex}"
      "    key_groups:"
      "      - pgp: *gpg"
    ]
    ++ lib.optional (ageKeys != [ ]) "        age: ${aliases ageKeys}";
in
{
  # each file there, by the keys that should open it
  recipients = lib.filterAttrs (file: keys: builtins.pathExists (../. + "/${file}")) (
    {
      "secrets/fleet.yaml" =
        settings.keys.encryption ++ map (machine: machine.features.secrets.ageKey) withKeys;
    }
    // lib.listToAttrs (
      map (machine: {
        name = "secrets/${machine.hostname}.yaml";
        value =
          settings.keys.encryption
          ++ lib.optional machine.features.secrets.active machine.features.secrets.ageKey;
      }) machines
    )
  );

  text = lib.concatLines (
    [
      "# made by nix/sops.nix, with nix build .#sops-config"
      "keys:"
      "  - &gpg [ ${lib.concatStringsSep ", " settings.keys.encryption} ]"
    ]
    ++ map (machine: "  - &${machine.hostname} ${machine.features.secrets.ageKey}") withKeys
    ++ [ "creation_rules:" ]
    # each machine's own, for it alone
    ++ lib.concatMap (
      hostname: rule "secrets/${lib.escapeRegex hostname}\\.yaml$" [ hostname ]
    ) hostnames
    # every machine's
    ++ rule "secrets/fleet\\.yaml$" hostnames
    # the rest, until their machine has a key
    ++ rule "secrets/" [ ]
  );
}
