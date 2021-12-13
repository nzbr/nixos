{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  config = mkIf (config.nzbr.service.syncthing.enable && config.services.xserver.enable)
    (
      let
        syncthingtray = (pkgs.syncthingtray.override {
          kioPluginSupport = false;
          plasmoidSupport = config.services.xserver.desktopManager.plasma5.enable;
        });
      in
      {
        environment.systemPackages = [
          syncthingtray
        ];

        nzbr.home.autostart = [
          "${syncthingtray}/share/applications/syncthingtray.desktop"
        ];

      }
    );
}
