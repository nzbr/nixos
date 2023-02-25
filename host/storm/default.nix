{ config, lib, pkgs, ... }:
{
  networking = {
    hostId = "e23e7d0a";
  };

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];
    nodeIp = "100.87.184.78";

    deployment.targetHost = "storm.nzbr.de";

    boot = {
      grub.enable = true;
      remoteUnlock = {
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
      tailscale.enable = true;
      # ceph.enable = true;
      gitlab-runner = {
        enable = true;
        extraTags = [ ];
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
    };
  };

  nirgenx = {
    enable = true;
    kubeconfigPath = "/run/kubeconfig";
    waitForUnits = [ "network-online.target" "k3s.service" ];
    helmNixPath = config.nzbr.flake.root;
    helmPackage = pkgs.kubernetes-helm;
    kubectlPackage = pkgs.kubectl;
    deployment = {
      amp.enable = true;
      # birdsite.enable = true;
      cert-manager.enable = true;
      # debug-shell.enable = true;
      gitlab.enable = true;
      hedgedoc.enable = true;
      kadalu.enable = true;
      keycloak.enable = true;
      matrix.enable = true;
      n8n.enable = true;
      nextcloud.enable = true;
      nginx.enable = true;
      openldap.enable = true;
      pingcheck.enable = true;
      plex.enable = true;
      stash.enable = true;
      vaultwarden.enable = true;
    };
  };

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

  services.postgresql =
    let
      services = [
        "bitwarden"
        "hedgedoc"
        "keycloak"
        "n8n"
        "synapse"
        "vaultwarden"
      ];
    in
    {
      enable = true;
      package = pkgs.postgresql_13;
      dataDir = "/storage/postgres/${config.services.postgresql.package.psqlSchema}";
      enableTCPIP = true;
      authentication = ''
        host all all 10.42.0.0/24 md5
        host all all 10.12.0.0/16 md5
        host all all 100.64.0.0/10 md5
      '';
      ensureDatabases = services;
      ensureUsers =
        map
          (name: {
            inherit name;
            ensurePermissions = {
              "DATABASE ${name}" = "ALL PRIVILEGES";
            };
          })
          services;
      initialScript = config.nzbr.assets."postgres-setup.sql";
    };
  services.postgresqlBackup = {
    enable = true;
    location = "/storage/postgres/backup";
    compression = "none";
    databases = config.services.postgresql.ensureDatabases;
  };
  systemd.tmpfiles.rules = [
    "d /storage/postgres 0755 postgres users"
  ];
  age.secrets."postgres-setup.sql".owner = "postgres";

  services.ceph.osd.daemons = [ "0" ];

  services.k3s = {
    enable = true;
    role = "server";
    dbEndpoint = "sqlite:///storage/kubernetes/kine.db?_journal=wal";
  };

  system.stateVersion = "21.11";
  nzbr.home.config.home.stateVersion = "22.05";
}
