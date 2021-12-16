{ config, lib, pkgs, ... }:
{
  nzbr = {
    # deployment.targetHost = ""
    patterns = [ "common" "desktop" "vmware" ];
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
