{ config, lib, pkgs, modulesPath, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    unstable.lutris
  ];

  hardware.xpadneo.enable = true;
  services.hardware.xow.enable = true;
}
