{
  user = {
    # the account you log in as, on every machine
    name = "siraj";
  };

  timeZone = "Europe/London";

  # Where this repository is cloned, under the home directory.
  # symlinkToCheckout (nix/make.nix) links the features' files there.
  checkout = "dotfiles";

  # features/gpg/public.asc
  git = {
    name = "syhner";
    email = "71605633+syhner@users.noreply.github.com";
  };

  # gpg --show-keys --with-subkey-fingerprints --with-keygrip features/gpg/public.asc
  keys = {
    # git's signing subkey
    signing = "0830D94DD20025E0DF05121CA18347D6D780B89E";
    # who can edit secrets/; each named with ! as GPG otherwise picks the newest
    encryption = [
      "6A6977BB860520B67871785B573B5C297F18A0F8!"
      "EBA99B588003FF31EE13518008F075642356614A!"
    ];
    # the authentication subkey; gpg --export-ssh-key <its id>
    ssh = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGt0dCkMKxbNo/zrW1JyKYPjXZaH6eofIF8N9T2luwZu openpgp:0x8EEB1153";
      keygrip = "54ED8998CD56573BDDF46513303B3909772E4985";
    };
  };

  tailscale = {
    # Tailscale admin → DNS: turn on MagicDNS, then its tailnet DNS name
    tailnet = "bone-luma.ts.net";

    # Tailscale admin → Settings → Trust credentials → OpenID Connect, for CI to build on the fleet:
    # issuer https://token.actions.githubusercontent.com, subject repo:<owner>/<repo>:ref:refs/heads/main,
    # claims repository_id and repository_owner_id, auth_keys scope (write), tag tag:ci.
    # null: CI builds on GitHub's runners, and only evaluates the macOS configurations.
    ciCredential = {
      clientId = "TKB77U63yy11CNTRL-kamP9Bdv4K11CNTRL";
      audience = "api.tailscale.com/TKB77U63yy11CNTRL-kamP9Bdv4K11CNTRL";
    };
  };

  # The Cachix cache CI pushes to (see .github/workflows/ci.yml), at
  # https://<name>.cachix.org.
  cachix = {
    name = "syhner";
    publicKey = "syhner.cachix.org-1:POzESTEAutt2R7M9JIZgrHabHtbi8/UXzueoc8q4cPU=";
  };
}
