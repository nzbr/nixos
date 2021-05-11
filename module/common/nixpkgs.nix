{ config, lib, pkgs, modulesPath, ... }:
let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";

  findModules = with builtins; with lib; dir: flatten (mapAttrsToList (name: type:
    if type == "directory" then
      findModules (dir + "/${name}")
    else
      let
        fileName = dir + "/${name}";
      in
        if hasSuffix ".pkg.nix" fileName
          then fileName
          else []
  ) (readDir dir));
in
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
      local = lib.listToAttrs (builtins.map (
        pkg:
          let
            package = pkgs.callPackage (import pkg) {};
          in
            lib.nameValuePair package.pname package
      ) (findModules ../../pkg));
    };
  };
}
