{ config, lib, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
with lib;
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
    nodeIp6 = "fd7a:115c:a1e0:ab12:4843:cd96:6261:616b";

    deployment.targetHost = "firestorm.nzbr.net";

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
        systems = [ "x86_64-linux" ];
      };
      mullvad-bridge = {
        enable = true;
        enabledRegions = [ "de-fra" "nl" "us" ];
        tailscale = true;
      };
      tailscale = {
        enable = true;
        exit = true;
      };
      # gitlab-runner = {
      #   enable = true;
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
  environment.etc."zfs/zed.d/zed.rc".source = mkForce config.nzbr.assets."zed.rc";

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

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "8192";
  }];

  services.k3s = {
    enable = true;
    role = "server";
    # dbEndpoint = "sqlite:///storage/kubernetes/kine.db?_journal=wal";
    dbEndpoint = "mysql://";
  };
  nirgenx = {
    enable = true;
    kubeconfigPath = "/run/kubeconfig";
    waitForUnits = [ "network-online.target" "k3s.service" ];
    helmNixPath = config.nzbr.flake.root;
    helmPackage = pkgs.kubernetes-helm;
    kubectlPackage = pkgs.kubectl;
    deployment = {
      # amp.enable = true;
      audiobookshelf.enable = true;
      argocd.enable = true;
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

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "generate-kubeconfig" ''
      # based on https://stackoverflow.com/questions/47770676/how-to-create-a-kubectl-config-file-for-serviceaccount
      SERVER=https://k8s.nzbr.de
      NAME=admin-token

      TOKEN=$(${pkgs.kubectl}/bin/kubectl get secret $NAME -o jsonpath='{.data.token}' | ${pkgs.coreutils}/bin/base64 --decode)

      cat <<EOF
      apiVersion: v1
      kind: Config
      clusters:
        - name: ${config.networking.hostName}
          cluster:
            server: $SERVER
      contexts:
        - name: ${config.networking.hostName}
          context:
            cluster: ${config.networking.hostName}
            user: default-user
            namespace: default
      current-context: ${config.networking.hostName}
      users:
        - name: default-user
          user:
            token: $TOKEN
      EOF
    '')
  ];

  services.postgresql =
    let
      services = [
        "bitwarden"
        "hedgedoc"
        "keycloak"
        "matrixslidingsync"
        "n8n"
        "outline"
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
            ensureDBOwnership = true;
          })
          services;
    };
  systemd.services.postgres-init = rec {
    requires = [ "postgresql.service" ];
    after = requires;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.systemd.services.postgresql.serviceConfig.User;
      Group = config.systemd.services.postgresql.serviceConfig.Group;
      ExecStart = "${config.services.postgresql.package}/bin/psql -f ${config.nzbr.assets."postgres-setup.sql"}";
    };
  };
  age.secrets."postgres-setup.sql".owner = "postgres";
  services.postgresqlBackup = {
    enable = true;
    location = "/storage/postgres/backup";
    compression = "none";
    databases = config.services.postgresql.ensureDatabases;
  };

  services.mysql =
    let
      services = [];
    in
    {
      enable = true;
      package = pkgs.mariadb;
      dataDir = "/storage/mysql/data";
      ensureDatabases = services ++ [
        "kubernetes"
      ];
      ensureUsers = (map
        (name: {
          inherit name;
          ensurePermissions = {
            "${name}.*" = "ALL PRIVILEGES";
          };
        })
        services
        ) ++ [
          {
            name = "mysql";
            ensurePermissions = {
              "*.*" = "ALL PRIVILEGES";
            };
          }
        ];
      settings.mysqld = {
        "character_set_server" = "utf8mb4";
        "collation_server" = "utf8mb4_general_ci";
      };
    };
  systemd.services.mysql-init = rec {
    requires = [ "mysql.service" ];
    after = requires;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.services.mysql.package}/bin/mysql -u root --batch < ${config.nzbr.assets."mysql-setup.sql"}'";
    };
  };
  age.secrets."mysql-setup.sql".owner = "mysql";
  services.mysqlBackup = {
    enable = true;
    location = "/storage/mysql/backup";
    singleTransaction = true;
    databases = config.services.mysql.ensureDatabases;
  };

  systemd.tmpfiles.rules = [
    "d /storage/postgres 0755 postgres postgres"
    "d /storage/mysql/data 0755 mysql mysql"
  ];

  services.mailmover = {
    enable = true;
    schedule = "*-*-* *:*:1";
    configFile = config.nzbr.assets."mailmover-config.dhall";
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;
  networking.firewall.trustedInterfaces = [ "docker0" ];

  # firewall rules for any-sync
  networking.firewall.allowedTCPPorts = [ 1011 1012 1013 1014 1015 1016 ];
  networking.firewall.allowedUDPPorts = [ 1011 1012 1013 1014 1015 1016 ];

  # nspawn containers

  networking.bridges.nspawn0.interfaces = [ ];
  networking.interfaces.nspawn0.ipv4.addresses = [{ address = "10.16.0.1"; prefixLength = 16; }];
  networking.interfaces.nspawn0.ipv6.addresses = [{ address = "fd00:10:16::1"; prefixLength = 64; }];
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "nspawn0" ];
  };
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          "nspawn0"
        ];
      };
      option-data = [
        { name = "domain-name"; data = "nspawn.local"; }
        { name = "domain-name-servers"; data = "100.100.100.100, 8.8.8.8"; }
        { name = "routers"; data = "10.16.0.1"; }
      ];
      subnet4 = [
        {
          pools = [
            {
              pool = "10.16.0.2 - 10.16.254.254";
            }
          ];
          subnet = "10.16.0.0/16";
        }
      ];
      valid-lifetime = 2592000; # 30 days
    };
  };
  services.radvd = {
    enable = true;
    config = ''
      interface nspawn0 {
        AdvSendAdvert on;
        AdvManagedFlag on;
        AdvOtherConfigFlag on;
        prefix fd00:10:16::/64 {
          AdvOnLink on;
          AdvAutonomous on;
          AdvRouterAddr on;
        };
      };
    '';
  };

  systemd.services.nspawn-amp = {
    description = "AMP Container";
    restartIfChanged = true;
    wantedBy = [ "machines.target" ];
    wants = [ "network.target" ];
    after = [ "network.target" ];
    path = [ config.systemd.package ];
    serviceConfig = {
      Type = "notify";
      Slice = "machine.slice";
      Delegate = true;
      KillMode = "mixed";
      KillSignal = "TERM";
      ExecStart = concatStringsSep " " [
        "systemd-nspawn"
        "--keep-unit"
        "--notify-ready=yes"
        "-M amp"
        "--boot"
        "--hostname amp"
        "--network-bridge=nspawn0"
        "--system-call-filter=\"add_key keyctl bpf\"" # Magic incantation to make docker work inside the container
        "-D /var/lib/machines/amp"
      ];
    };
  };

  virtualisation.oci-containers.containers.fachprojekt-runner = {
    autoStart = true;
    image = "gitea/act_runner:latest";
    volumes = [
      "/var/lib/fachprojekt-runner:/data"
      "${config.nzbr.assets."fachprojekt-runner-token"}:/token"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    environment = {
      GITEA_INSTANCE_URL = "https://git.cs.tu-dortmund.de";
      GITEA_RUNNER_REGISTRATION_TOKEN_FILE = "/token";
      GITEA_RUNNER_NAME = "firestorm";
      GITEA_RUNNER_LABELS = "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest";
    };
    extraOptions = [
      "--label=com.centurylinklabs.watchtower.enable=true"
    ];
  };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}
