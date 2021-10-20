{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.container.watchtower.enable = mkEnableOption "Watchtower container (auto-updates docker containers)";

  config = mkIf config.nzbr.container.watchtower.enable {
    virtualisation.oci-containers.containers.watchtower = {
      image = "containrrr/watchtower";
      environment = {
        TZ = "Europe/Berlin";
        WATCHTOWER_CLEANUP = "true";
        WATCHTOWER_POLL_INTERVAL = "10800";
      };
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
