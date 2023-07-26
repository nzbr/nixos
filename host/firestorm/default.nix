{ config, lib, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
{
  imports = [
    ./disk-configuration.nix
  ];

  networking = {
    hostId = "5e6de721";
  };

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];
    # nodeIp = "";

    deployment.targetHost = "firestorm.nzbr.de";

    boot = {
      remoteUnlock = {
        enable = true;
        # tailscale = true;
        luks = false;
        zfs = [ "zroot" ];
      };
    };

    network.k3s-firewall.enable = true;

    service = {
      buildServer = {
        enable = true;
        maxJobs = 6;
        systems = [ "x86_64-linux" "i686-linux" ];
      };
      # tailscale = {
      #   enable = true;
      #   exit = true;
      # };
      # gitlab-runner = {
      #   enable = true;
      #   extraTags = [ "kube-deploy" ];
      # };
      # synapse.enable = true;
    };
  };

  boot = {
    loader = {
      efi = {
        efiSysMountPoint = "/boot";
      };
      systemd-boot.enable = true;
    };

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

  # fileSystems = {
  # }
  # //
  # lib.mapAttrs'
  #   (to: from:
  #     {
  #       name = to;
  #       value = {
  #         device = from;
  #         options = [ "bind" ];
  #       };
  #     }
  #   )
  #   {
  #     "/var/lib/rancher/k3s/storage" = "/storage/kubernetes/local-path";
  #     "/var/lib/longhorn" = "/storage/kubernetes/longhorn";
  #     "/var/lib/rook" = "/storage/kubernetes/rook";
  #     "/var/lib/etcd" = "/storage/kubernetes/etcd";
  #     "/var/lib/ceph" = "/storage/ceph";
  #   };

  # swapDevices = [
  #   {
  #     device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-0-part3";
  #     randomEncryption.enable = true;
  #   }
  # ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.qemuGuest.enable = true;

  networking = {
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    interfaces.ens3 = {
      useDHCP = true;
      ipv6 = {
        addresses = [{
          address = "2a03:4000:b:120::1";
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

  # services.mailmover = {
  #   enable = true;
  #   schedule = "*-*-* *:*:1";
  #   configFile = config.nzbr.assets."mailmover-config.dhall";
  # };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}
