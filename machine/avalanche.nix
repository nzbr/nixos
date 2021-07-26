{ config, lib, pkgs, modulesPath, ... }:
{
  networking = {
    hostName = "avalanche";
    hostId = "24071395";
  };

  imports = [
    ../module/common/boot/grub.nix
    ../module/common/service/wireguard.nix

    ../module/server.nix
    ../module/server/restic.nix
    ../module/server/service/k3s.nix
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    loader.grub.configurationLimit = 1;

    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
      supportedFilesystems = [ "zfs" ];
    };
    kernelModules = [ ];
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "zroot";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/F3BE-8A41";
      fsType = "vfat";
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
    "/nix/store" = {
      device = "zroot/nix-store";
      fsType = "zfs";
    };

    "/storage/kubernetes" = {
      device = "zroot/kubernetes";
      fsType = "zfs";
    };
  }
  //
  lib.mapAttrs'
    (to: from:
      {
        name = to;
        value = {
          device = from;
          options = [ "bind" ];
        };
      }
    )
    {
      "/var/lib/rancher/k3s/storage" = "/storage/kubernetes/local-path";
      "/var/lib/longhorn" = "/storage/kubernetes/longhorn";
      "/var/lib/etcd" = "/storage/kubernetes/etcd";
    };

  swapDevices = [
    {
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-0-part3";
      randomEncryption.enable = true;
    }
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  nzbr.remote-unlock = {
    luks = false;
    zfs = [ "zroot" ];
  };

  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.enp0s3 = {
      useDHCP = true;
    };
  };

  nzbr.wgIp = "10.42.0.4";
  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.42.0.4/24"
      "fs42:42::88fc:d9ff:fe45:ead8/64"
    ];
    peers = [
      {
        # storm
        publicKey = (lib.fileContents ../secret/storm/wireguard/public.key);
        endpoint = "storm.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.0/26"
          "fd42:42::/32"
          "172.18.0.0/16" # storm's Docker network
        ];
      }
      {
        # earthquake
        publicKey = (lib.fileContents ../secret/earthquake/wireguard/public.key);
        endpoint = "earthquake.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.2/32"
          "fd42:42::7a24:afff:febc:c07/128"
        ];
      }
    ];
  };

  nzbr.restic = {
    remote = "jotta-archive";
    include = [
      "zroot/etc"
      "zroot/home"
      "zroot/root"
      "zroot/srv"
      "zroot/storage"
    ];
    healthcheck = {
      backup = "https://hc-ping.com/a4db4963-0a73-4aeb-8207-f884341ba04d";
      prune = "https://hc-ping.com/be3cdc9a-3eb4-4f85-b8ad-c51dc361f9e7";
    };
    pools = [
      {
        name = "zroot";
        subvols = [
          { name = "nix-store"; mountpoint = "/nix/store"; }
          { name = "kubernetes"; mountpoint = "/storage/kubernetes"; }
        ];
      }
    ];
  };
}
