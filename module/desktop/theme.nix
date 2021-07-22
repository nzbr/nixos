{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    pop-gtk-theme
    local.papirus-icon-theme-mod
  ];
}
