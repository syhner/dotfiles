{
  username = "siraj";

  timeZone = "Europe/London";

  gitUser = {
    name = "syhner";
    email = "71605633+syhner@users.noreply.github.com";
    signingKey = "0830D94DD20025E0DF05121CA18347D6D780B89E";
  };

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGt0dCkMKxbNo/zrW1JyKYPjXZaH6eofIF8N9T2luwZu openpgp:0x8EEB1153";
  sshKeygrip = "54ED8998CD56573BDDF46513303B3909772E4985";

  # The binary cache CI pushes to (see .github/workflows/ci.yml).
  cache = {
    url = "https://syhner.cachix.org";
    publicKey = "syhner.cachix.org-1:POzESTEAutt2R7M9JIZgrHabHtbi8/UXzueoc8q4cPU=";
  };
}
