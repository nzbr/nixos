{ config, lib, pkgs, ... }:
with builtins; with lib; {
  nzbr = {
    deployment.targetHost = "192.168.88.129";
    patterns = [ "desktop" "vmware" ];

    agenix.enable = mkForce true;
    nopasswd.enable = false;
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cr-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };
  boot.initrd.luks.devices."cr-root".device = "/dev/sda2";
}
