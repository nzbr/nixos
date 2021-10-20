{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.device.razerChroma = {
    enable = mkEnableOption "Razer Chroma support through OpenRazer";
  };

  config =
    let
      cfg = config.nzbr.device.razerChroma;
    in
    mkIf cfg.enable {
      hardware.openrazer = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [
        razergenie
      ];
    };
}
