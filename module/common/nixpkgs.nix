let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
in
{ config, lib, pkgs, modulesPath, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides.unstable = import unstableTarball {
      config = config.nixpkgs.config;
    };
  };
}
