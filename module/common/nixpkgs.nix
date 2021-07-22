{ config, lib, inputs, system, pkgs, modulesPath, ... }:
let
  findModules =
    with builtins; with lib;
    suffix: dir:
      flatten (
        mapAttrsToList
          (
            name: type:
              if type == "directory" then
                findModules suffix (dir + "/${name}")
              else
                let
                  fileName = dir + "/${name}";
                in
                if hasSuffix suffix fileName
                then fileName
                else [ ]
          )
          (readDir dir)
      );
  loadPackages =
    with builtins; with lib;
    channel: suffix: dir:
      listToAttrs (
        map
          (
            pkg:
            nameValuePair
              # String carries context of the derivation the file comes from.
              # It is only used to find the derivation that should carry that information anyway.
              # It should be safe to discard it. (I hope)
              (unsafeDiscardStringContext (removeSuffix suffix (baseNameOf pkg)))
              (channel.callPackage (import pkg) { })
          )
          (
            findModules suffix dir
          )
      );
in
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = {
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = config.nixpkgs.config;
      };
      legacy = import inputs.nixpkgs-legacy {
        inherit system;
        config = config.nixpkgs.config;
      };
      ragon = import inputs.ragon {
        inherit system;
        config = config.nixpkgs.config;
      };
      local = loadPackages pkgs ".pkg.nix" ../../pkg;
      comma = pkgs.callPackage (import inputs.comma) { };
    };
  };
}
