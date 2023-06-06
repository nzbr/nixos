{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  networking.hostId = "8c979594";

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];

    deployment.targetHost = "permafrost.dragon-augmented.ts.net";

    boot = {
      grub.enable = true;
      remoteUnlock = {
        enable = true;
        luks = false;
        zfs = [ "zroot" ];
      };
    };

    service = {
      tailscale = {
        enable = true;
      };
    };
  };

  boot = {
    loader = {
      grub = {
        efiSupport = true;
        copyKernels = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    initrd = {
      kernelModules = [
        "r8169" # Early boot network
      ];
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "hid_roccat"
        "hid_roccat_common"
        "hid_roccat_isku"
      ];
      supportedFilesystems = [ "zfs" ];
    };
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "zfs" ];
  };

  fileSystems =
    let
      zfsOnLuks = name: uuid: {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "ro" "size=0" ];
        encrypted = {
          enable = true;
          blkDev = "/dev/disk/by-uuid/${uuid}";
          label = name;
          keyFile = "/mnt-root/etc/lukskey";
        };
      };
    in
    {
      "/" = {
        device = "zroot";
        fsType = "zfs";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/2B0D-D4B4";
        fsType = "vfat";
      };
      "/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "size=16G" ];
      };

      # "/run/.luks/cr_storage_1" = zfsOnLuks "cr_storage_1" "7e8de2a9-5cd0-4475-8a99-9d436604e639";
      # "/run/.luks/cr_storage_2" = zfsOnLuks "cr_storage_2" "b3c32804-ab03-45cf-8e74-1e6f59969d5a";
      # "/run/.luks/cr_storage_3" = zfsOnLuks "cr_storage_3" "b6bba72c-ceb4-4116-89bb-8a9197059600";

      # "/run/.luks/cr_backup_1" = zfsOnLuks "cr_backup_1" "942c4a41-edcc-4a60-8528-42db7a782c44";
      # "/run/.luks/cr_backup_2" = zfsOnLuks "cr_backup_2" "c1261cce-9627-42c0-91a2-c36a534d76a6";
    };

  # boot.zfs.extraPools = [ "hoard" "zbackup" ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/5b42f06e-fe01-4c46-a69c-b5dfd1f8ebf4";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.enp5s0 = {
      useDHCP = true;
    };
    tempAddresses = "disabled";
    dhcpcd.extraConfig = ''
      slaac hwaddr
    '';
  };

  system.stateVersion = "22.11";
  nzbr.home.config.home.stateVersion = "22.11";
}
