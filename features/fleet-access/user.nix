# The user the fleet's machines log in to each other as (see default.nix).
rec {
  name = "fleet-servant";
  # on macOS; on NixOS, it's a system user with none
  home = "/var/lib/fleet-servant";
  # Nix's store at a machine, reached as this user
  storeUri = address: "ssh-ng://${name}@${address}";
}
