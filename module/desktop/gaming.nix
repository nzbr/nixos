{ config, lib, pkgs, modulesPath, ... }:
{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    unstable.lutris
  ];
}
