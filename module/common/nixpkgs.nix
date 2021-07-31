{ config, lib, inputs, system, pkgs, local-pkgs, modulesPath, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = {
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = config.nixpkgs.config;
      };
      bleeding-edge = import inputs.nixpkgs-bleeding-edge {
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
      local = local-pkgs;
      comma = pkgs.callPackage (import inputs.comma) { };
    };
  };
}
