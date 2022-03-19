{ config, lib, pkgs, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" ];

    agenix.enable = false;
    nopasswd.enable = mkDefault true;
    autologin.enable = mkDefault true;

    boot.grub.enable = true;
    boot.plymouth.enable = false;
  };

  fileSystems = {
    "/" = mkDefault {
      device = "/dev/sda2";
      fsType = "ext4";
    };
    "/boot" = mkDefault {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };

  systemd.network.enable = mkDefault true;
  systemd.network.networks."lan" = {
    enable = mkDefault true;
    matchConfig.Name = "e*";
    DHCP = "ipv4";
  };

  networking.usePredictableInterfaceNames = mkDefault false;
  networking.wireless = {
    enable = mkForce false;
    iwd.enable = mkForce false;
  };

}
