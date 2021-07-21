{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./desktop.nix
  ];

  powerManagement.cpuFreqGovernor = "conservative";
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

}
