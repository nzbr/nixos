{ config, lib, pkgs, modulesPath, ... }:
{
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.extraModules = [ pkgs.pulseaudio-modules-bt ];
}
