{ config, lib, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
{
  networking = {
    hostId = "24071395";
  };

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];
    nodeIp = "100.86.174.117";

    deployment.targetHost = "avalanche.nzbr.de";

    boot = {
      grub.enable = true;
      remoteUnlock = {
        enable = true;
        tailscale = true;
        luks = false;
        zfs = [ "zroot" ];
      };
    };

    network.k3s-firewall.enable = true;

    service = {
      buildServer = {
        enable = true;
        maxJobs = 4;
        systems = [ "x86_64-linux" "i686-linux" ];
      };
      tailscale = {
        enable = true;
        exit = true;
      };
      # ceph.enable = true;
      gitlab-runner = {
        enable = true;
        extraTags = [ "kube-deploy" ];
      };
      restic = {
        enable = true;
        remote = "jotta-archive";
        include = [
          "zroot/etc"
          "zroot/home"
          "zroot/root"
          "zroot/srv"
          "zroot/storage"
          "zroot/var/lib/rancher/k3s"
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
      # synapse.enable = true;
    };
  };

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
      "/var/lib/rook" = "/storage/kubernetes/rook";
      "/var/lib/etcd" = "/storage/kubernetes/etcd";
      "/var/lib/ceph" = "/storage/ceph";
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
  nzbr.service.libvirtd.enable = true;

  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.ens3 = {
      useDHCP = true;
      ipv6 = {
        addresses = [{
          address = "2a03:4000:53:7a::";
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

  # services.ceph.osd.daemons = [ "1" ];

  # services.k3s = {
  # enable = true;
  # role = "agent";
  # };

  system.stateVersion = "21.11";
  nzbr.home.config.home.stateVersion = "22.05";
}
