{ config, lib, pkgs, modulesPath, ... }:
let
  nixos-hardware = builtins.fetchGit {
    url = "https://github.com/NixOS/nixos-hardware.git";
    ref = "master";
  };
in
{
  networking.hostName = "meteor";

  imports = [
    "${nixos-hardware}/lenovo/thinkpad/t420"

    ../module/common/boot/grub.nix
    ../module/common/service/printing.nix
    ../module/common/service/syncthing.nix
    ../module/desktop.nix
    ../module/desktop/development.nix
    ../module/desktop/gnome.nix
    ../module/desktop/office.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" "f2fs" "xfs" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cr_root";
      fsType = "f2fs";
      neededForBoot = true;
    };
    "/home" = {
      device = "/dev/mapper/cr_home";
      fsType = "xfs";
      neededForBoot = false;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
  };

  boot.initrd = {
    luks.devices = {
      "cr_root" = {
        device = "/dev/disk/by-uuid/4fe2eb8b-ff38-42b1-8e23-a9fcadd899c5";
        keyFile = "/lukskey";
      };
      "cr_home" = {
        device = "/dev/disk/by-uuid/ccb4975c-9668-4389-9ed8-3d6d6f42d7d1";
        keyFile = "/lukskey";
      };
    };
    secrets = {
      "lukskey" = ../secret + "/${config.networking.hostName}/lukskey";
    };
  };

  swapDevices = [
    { device = "/swapfile"; }
  ];
}
