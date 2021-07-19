{ config, lib, pkgs, modulesPath, ... }:
{
  virtualisation.docker = {
    enable = true;
  };
  virtualisation.oci-containers = {
    backend = "docker";
  };
}
