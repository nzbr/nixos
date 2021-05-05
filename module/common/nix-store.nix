{ config, lib, pkgs, modulesPath, ... }:
{
  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
  };
}
