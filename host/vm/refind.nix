{ config, lib, pkgs, ... }:
{
  nzbr = {
    deployment.targetHost = "192.168.88.133";
    patterns = [ "desktop" "vmware" ];
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
