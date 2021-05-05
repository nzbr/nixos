{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./common.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_hardened;
}
