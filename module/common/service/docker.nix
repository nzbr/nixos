{ config, lib, pkgs, modulesPath, ... }:
{
  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };
}
