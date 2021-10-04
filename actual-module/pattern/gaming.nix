{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.pattern.gaming.enable = mkEnableOption "Gaming";

  config = mkIf config.nzbr.pattern.gaming.enable {
    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
      unstable.lutris
    ];

    hardware.xpadneo.enable = true;
    services.hardware.xow.enable = true;
  };
}
