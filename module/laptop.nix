{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./desktop.nix
  ];

  powerManagement.cpuFreqGovernor = "conservative";
  services.thermald.enable = true;

}
