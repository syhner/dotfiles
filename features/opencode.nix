{ unstable, ... }:
let
  # nixpkgs' opencode 2.2.5 node_modules hash doesn't match what bun produces
  # on darwin. Drop this override once nixpkgs-unstable fixes it.
  opencode =
    if unstable.stdenv.hostPlatform.isDarwin then
      unstable.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc=";
        };
      })
    else
      unstable.opencode;
in
{
  tags = [ "dev" ];
  packages = [ opencode ];
}
