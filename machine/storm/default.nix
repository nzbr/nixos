{ config, lib, root, ... }:
{
  networking = {
    hostName = "storm";
    hostId = "e23e7d0a";
  };

  imports = [
    "${root}/module/common/boot/grub.nix"
    "${root}/module/common/service/wireguard.nix"

    "${root}/module/server.nix"
    "${root}/module/server/restic.nix"
    "${root}/module/server/service/k3s.nix"
  ];

  boot = {
    loader.grub.device = "/dev/sda";

    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"

        "virtio_net" # Early boot network
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
      device = "/dev/disk/by-uuid/86B8-C470";
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
      "/var/lib/rook" = "/storage/kubernetes/rook";
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

  services.qemuGuest.enable = true;

  nzbr.remote-unlock = {
    luks = false;
    zfs = [ "zroot" ];
  };

  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.ens3 = {
      useDHCP = true;
      ipv6 = {
        addresses = [{
          address = "2a03:4000:45:510::";
          prefixLength = 64;
        }];
        routes = [{
          address = "::";
          prefixLength = 0;
          via = "fe80::1";
        }];
      };
    };
  };

  nzbr.wgIp = "10.42.0.1";
  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.42.0.1/24"
      "fd42:42::b45c:e0ff:fe75:cb6a/64"
    ];
    peers = [
      {
        # earthquake
        publicKey = (lib.fileContents config.nzbr.foreignAssets.earthquake."wireguard/public.key");
        endpoint = "earthquake.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.2/32"
          "fd42:42::7a24:afff:febc:c07/128"
        ];
      }
      {
        # avalanche
        publicKey = (lib.fileContents config.nzbr.foreignAssets.avalanche."wireguard/public.key");
        endpoint = "avalanche.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.4/32"
          "fd42:42::88fc:d9ff:fe45:ead8/128"
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
      backup = "https://hc-ping.com/6d9994af-6806-4cf1-91ee-3a217176df7f";
      prune = "https://hc-ping.com/433ab5bb-9267-4dda-b5a9-5fa8573f5ed8";
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

  services.postgresql =
    let
      services = [
        "bitwarden"
        "nextcloud"
      ];
    in
    {
      enable = true;
      dataDir = "/storage/postgres/${config.services.postgresql.package.psqlSchema}";
      enableTCPIP = true;
      ensureDatabases = services;
      ensureUsers = map
        (name: {
          inherit name;
          ensurePermissions = {
            "DATABASE ${name}" = "ALL PRIVILEGES";
          };
        })
        services;
      initialScript = config.nzbr.assets."postgres-setup.sql";
    };
  systemd.tmpfiles.rules = [
    "d /storage/postgres 0755 postgres users"
  ];
  age.secrets."postgres-setup.sql".owner = "postgres";
}
