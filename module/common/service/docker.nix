{ config, lib, pkgs, modulesPath, ... }:
{
  virtualisation.docker = {
    enable = true;
    package = pkgs.unstable.docker;
  };
}
