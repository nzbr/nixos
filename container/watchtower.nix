{ config, lib, pkgs, modulesPath, ... }:
{
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
}
