{ pkgs, ... }:
{
  tags = [ "dev" ];

  packages = [
    # Backport nixd#828: empty hover contents violate the LSP specification.
    (pkgs.nixd.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./nixd-empty-hover.patch ];
    }))
  ];
}
