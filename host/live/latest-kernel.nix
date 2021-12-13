{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.enableUnstable = true;
  nixpkgs.config.allowBroken = true;
}
