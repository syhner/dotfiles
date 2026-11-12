# Lint checks, for nix flake check and CI's lint job.
{
  pkgs,
  formatter,
  sopsConfig,
  sopsRecipients,
  src,
}:
let
  # Runs script in a writable copy of src, the flake's source.
  check =
    name: packages: script:
    pkgs.runCommand name { nativeBuildInputs = packages; } ''
      cp -r ${src} source
      chmod -R u+w source
      cd source
      ${script}
      touch $out
    '';
in
{
  # fails if nix fmt would change anything (--tree-root, as there's no .git in the build)
  nixfmt = check "nixfmt" [ formatter ] "treefmt --ci --tree-root .";

  # fails if .sops.yaml isn't what nix/sops.nix makes
  sops-config = check "sops-config" [ ] ''
    diff -u .sops.yaml ${sopsConfig} || {
      echo 'out of date: install -m 644 "$(nix build --no-link --print-out-paths .#sops-config)" .sops.yaml'
      exit 1
    }
  '';

  # fails if a file in secrets/ isn't encrypted for exactly the keys it should be
  sops-recipients = check "sops-recipients" [ pkgs.yq-go ] (
    pkgs.lib.concatStrings (
      pkgs.lib.mapAttrsToList (file: keys: ''
        diff -u <(printf '%s\n' ${pkgs.lib.escapeShellArgs (pkgs.lib.sort (a: b: a < b) keys)}) \
          <(yq '(.sops.age // [])[].recipient, (.sops.pgp // [])[].fp' ${file} | LC_ALL=C sort) || {
          echo 'out of date: sops updatekeys ${file}'
          exit 1
        }
      '') sopsRecipients
    )
  );

  shellcheck = check "shellcheck" [ pkgs.shellcheck ] "shellcheck .github/scripts/*.sh";

  # with shellcheck, it also checks the workflows' run: scripts
  actionlint = check "actionlint" [
    pkgs.actionlint
    pkgs.shellcheck
  ] "actionlint .github/workflows/*.yml";
}
