{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./common.nix
    ./server/remote-unlock.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_hardened;
}
