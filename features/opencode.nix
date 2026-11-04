{ unstable, ... }:
let
  # nixpkgs' opencode 2.2.5 node_modules hash doesn't match what bun produces,
  # which differs between darwin and linux. Drop this override once
  # https://github.com/NixOS/nixpkgs/pull/582675 reaches nixpkgs-unstable.
  opencode = unstable.opencode.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs {
      outputHash =
        if unstable.stdenv.hostPlatform.isDarwin then
          "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc="
        else
          "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
    };
  });
in
{
  tags = [ "dev" ];
  packages = [ opencode ];
}
