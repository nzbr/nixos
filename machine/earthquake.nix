{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "earthquake";

  imports = [
    ../module/common/boot/systemd-boot.nix
    ../module/server.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "hid_roccat"
        "hid_roccat_common"
        "hid_roccat_isku"
      ];
      kernelModules = [];
    };
    kernelModules = [ "dm-snapshot" "kvm-intel" ];
    extraModulePackages = [ ];
  };

  environment.etc."lukskey" = {
    source = ../secret + "/${config.networking.hostName}/lukskey";
    mode = "0400";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@" "ssd" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@/nix/store" "ssd" "noatime" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/799C-AA37";
      fsType = "vfat";
      neededForBoot = true;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
    "/storage" =
    let label = "cr_storage";
    in {
      device = "/dev/mapper/${label}";
      fsType = "btrfs";
      neededForBoot = false;
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/38627a12-ce2f-43ac-9cfd-24fc20e00e26";
        label = label;
        keyFile = "/mnt-root/etc/lukskey";
      };
    };
  };

  boot.initrd = {
    luks.devices = {
      "cr_root" = {
        device = "/dev/disk/by-uuid/13187d61-8666-4533-b853-fd32e20eed2c";
        preLVM = true;
      };
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/64f798e8-2382-4d82-9591-5616d368c30e";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  services.syncthing.dataDir = "/storage/NAS/nzbr";
}
