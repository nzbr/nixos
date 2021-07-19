let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  ragonTarball = builtins.fetchGit "https://github.com/ragon000/nixos-config.git";
  # ragonTarball = fetchTarball "https://gitlab.hochkamp.eu/ragon/nixos/-/archive/main/nixos-main.tar.gz?path=packages";
  # ragonTarball = ../../.ragon;
in
{ config, lib, pkgs, modulesPath, ... }:
let
  findModules =
    with builtins; with lib;
    suffix: dir:
      flatten (
        mapAttrsToList (
          name: type:
            if type == "directory" then
              findModules suffix (dir + "/${name}")
            else
              let
                fileName = dir + "/${name}";
              in
                if hasSuffix suffix fileName
                  then fileName
                  else []
        ) (readDir dir)
      );
  loadPackages =
    with builtins; with lib;
    channel: suffix: dir:
      listToAttrs (
        map (
          pkg:
            nameValuePair
              # String carries context of the derivation the file comes from.
              # It is only used to find the derivation that should carry that information anyway.
              # It should be safe to discard it. (I hope)
              (unsafeDiscardStringContext (removeSuffix suffix (baseNameOf pkg)))
              (channel.callPackage (import pkg) {})
        ) (
          findModules suffix dir
        )
      );
in
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
      local = loadPackages pkgs ".pkg.nix" ../../pkg;
      ragon = loadPackages pkgs.unstable ".nix" (ragonTarball + "/packages");
      comma = pkgs.callPackage (import (builtins.fetchGit "https://github.com/shopify/comma.git")) {};
    };
  };
}
