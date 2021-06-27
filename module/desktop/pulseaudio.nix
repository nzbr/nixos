{ config, lib, pkgs, modulesPath, ... }:
{
  hardware.pulseaudio.extraModules = [ pkgs.pulseaudio-modules-bt ];
}
