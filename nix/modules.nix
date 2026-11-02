# The modules in modules/ that have any of the given tags, in the order of their
# names. A configuration lists the tags that describe what its host is, and any
# modules on top, and gets nothing it doesn't ask for.
#
# The tags:
#   base         every host
#   workstation  a host I sit at and work on, rather than a server
#   darwin       a Mac
#
# A module is a file or folder in modules/ (a folder holds default.nix and the
# files the module uses), and is an attribute set of these parts, in this order:
#   tags      the tags that pick it. Every module lists them, even if none.
#   unfree    names of the unfree packages it installs, from stable or unstable.
#             They can't use pkgs: they configure it (see nix/pkgs.nix).
#   packages  function from pkgs to the packages to install: system-wide, or
#             through Home Manager when it runs standalone (see
#             nix/packages.nix)
#   home      Home Manager module(s). The standalone argument says whether
#             Home Manager runs standalone, for doing the system part's job.
#   system    NixOS / nix-darwin module(s)
#
# A module that can be customised is a function from its arguments to that
# attribute set, as in import ../modules/platform-nixos { ssh = true; }. Tags
# pick it with its default arguments.
{ lib }:
let
  isModule = name: type: type == "directory" || lib.hasSuffix ".nix" name;
  modules = map (name: lib.toFunction (import ../modules/${name}) { }) (
    lib.attrNames (lib.filterAttrs isModule (builtins.readDir ../modules))
  );
in
tags: builtins.filter (module: lib.any (tag: builtins.elem tag tags) module.tags) modules
