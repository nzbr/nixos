{ config, lib, pkgs, modulesPath, ... }:
{
  boot.loader.systemd-boot = {
    enable = true;
  };
}
