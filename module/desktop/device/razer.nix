{ config, lib, pkgs, modulesPath, ... }:
{
  hardware.openrazer = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    razergenie
  ];
}
