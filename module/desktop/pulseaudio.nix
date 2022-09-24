{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.desktop.pulseaudio = {
    enable = mkEnableOption "Pulseaudio";
  };

  config = mkIf config.nzbr.desktop.pulseaudio.enable {
    sound.enable = true;
    hardware.pulseaudio.enable = true;
  };
}
