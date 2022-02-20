{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "desktop" "development" "gaming" ];
    pattern.development.guiTools = true;

    boot.grub.enable = true;

    service = {
      syncthing.enable = true;
      printing.enable = true;
    };

    program = {
      latex.enable = true;
    };
  };

  boot = {
    loader = {
      efi = {
        efiSysMountPoint = "/boot/efi";
      };
      grub = {
        efiSupport = true;
        copyKernels = false;
      };
    };

    initrd = {
      availableKernelModules = [ "ehci_pci" "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
      kernelModules = [ "dm-snapshot" ];

      luks.devices = {
        "cr_root" = {
          device = "/dev/disk/by-uuid/a4392fe9-1711-4ec2-9692-461740b2ab9e";
          preLVM = true;
          keyFile = "/lukskey";
        };
        "cr_home" = {
          device = "/dev/disk/by-uuid/e515efb4-20db-4845-8907-9fb308d18ea6";
          preLVM = true;
          keyFile = "/lukskey";
        };
      };
      secrets = {
        "lukskey" = "/etc/nixos/lukskey";
      };
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [ "video=VGA-1:1440x900@60" ];

    resumeDevice = "/dev/vg_ssd/swap";
  };

  fileSystems = {
    "/" = {
      device = "/dev/vg_ssd/root";
      fsType = "f2fs";
      neededForBoot = true;
    };
    "/boot/efi" = {
      device = "/dev/disk/by-uuid/CACB-F5DC";
      fsType = "vfat";
      neededForBoot = false;
    };
    "/home" = {
      device = "/dev/mapper/cr_home";
      fsType = "ext4";
      neededForBoot = false;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
  };

  swapDevices = [
    { device = "/dev/vg_ssd/swap"; }
  ];
}
