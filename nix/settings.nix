{
  username = "siraj";

  timeZone = "Europe/London";

  # Where this repository is cloned, under the home directory.
  # symlinkToCheckout (nix/make.nix) links the features' files there.
  checkout = "dotfiles";

  # features/gpg/public.asc
  gitUser = {
    name = "syhner";
    email = "71605633+syhner@users.noreply.github.com";
    signingKey = "0830D94DD20025E0DF05121CA18347D6D780B89E";
  };

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGt0dCkMKxbNo/zrW1JyKYPjXZaH6eofIF8N9T2luwZu openpgp:0x8EEB1153";
  sshKeygrip = "54ED8998CD56573BDDF46513303B3909772E4985";

  # The tailnet's MagicDNS domain. The fleet's machines reach each other at
  # names under it (machine.address in make.nix), which only machines on the
  # tailnet can resolve.
  tailnet = "bone-luma.ts.net";

  # CI's trust credential in the tailnet (Settings → Trust credentials), which
  # its build jobs join the tailnet with, as tag:ci, to build on the fleet
  # (see .github/workflows/ci.yml). Neither is secret: it only trusts this
  # repository's workflows, through GitHub's identity token. null for none.
  ciCredential = {
    clientId = "TKB77U63yy11CNTRL-kamP9Bdv4K11CNTRL";
    audience = "api.tailscale.com/TKB77U63yy11CNTRL-kamP9Bdv4K11CNTRL";
  };

  # The Cachix cache CI pushes to (see .github/workflows/ci.yml), at
  # https://<name>.cachix.org.
  cache = {
    name = "syhner";
    publicKey = "syhner.cachix.org-1:POzESTEAutt2R7M9JIZgrHabHtbi8/UXzueoc8q4cPU=";
  };
}
