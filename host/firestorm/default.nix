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
    nodeIp = "100.97.97.107";

    deployment.targetHost = "firestorm.nzbr.de";

    boot = {
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
        maxJobs = 6;
        systems = [ "x86_64-linux" "i686-linux" ];
      };
      tailscale = {
        enable = true;
        exit = true;
      };
      # gitlab-runner = {
      #   enable = true;
      #   extraTags = [ "kube-deploy" ];
      # };
      synapse.enable = true;
      borgbackup = {
        enable = true;
        repoUrl = "ssh://permafrost-backup/backup/${config.networking.hostName}";
        zfs.pools = [
          {
            name = "zroot";
            mountpoint = null;
            subvols = [
              { name = "root"; mountpoint = "/"; }
              { name = "nix-store"; mountpoint = "/nix/store"; }
              { name = "kubernetes"; mountpoint = "/storage/kubernetes"; }
            ];
          }
        ];
        paths = [
          "/dev/zvol/zroot/*@${config.nzbr.service.borgbackup.zfs.snapshotName}"
        ];
        healthcheckUrl = "https://hc-ping.com/f92f3bfb-a133-4e99-8248-b8acc91a39dd";
      };
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

  fileSystems = lib.mapAttrs'
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
    };

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

  services.k3s = {
    enable = true;
    role = "server";
    dbEndpoint = "sqlite:///storage/kubernetes/kine.db?_journal=wal";
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
      cert-manager.enable = true;
      # debug-shell.enable = true;
      gitlab.enable = true;
      hedgedoc.enable = true;
      kadalu.enable = true;
      keycloak.enable = true;
      matrix.enable = true;
      # n8n.enable = true;
      nextcloud.enable = true;
      nginx.enable = true;
      openldap.enable = true;
      # pingcheck.enable = true;
      plausible.enable = true;
      plex.enable = true;
      # stash.enable = true;
      vaultwarden.enable = true;
    };
  };

  services.postgresql =
    let
      services = [
        "bitwarden"
        "hedgedoc"
        "keycloak"
        "n8n"
        "plausible"
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

  services.mailmover = {
    enable = true;
    schedule = "*-*-* *:*:1";
    configFile = config.nzbr.assets."mailmover-config.dhall";
  };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}