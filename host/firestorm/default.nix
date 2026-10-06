{ config, lib, pkgs, modulesPath, ... }:
with lib;
let
  inherit (builtins) toJSON;
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
        # enable = true;
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
        repoUrl = "ssh://u523435-sub1@hetzner/home/repo";
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
      systemd.enable = false;
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

    kernel.sysctl."fs.inotify.max_user_watches" = "500000";
  };

  fileSystems = lib.mapAttrs'
    (to: from:
      {
        name = to;
        value = {
          device = from;
          options = [ "bind" ];
          fsType = "auto";
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
    manifests = {
      "01-argocd".content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "argocd";
          namespace = "kube-system";
        };
        spec = {
          repo = "https://argoproj.github.io/argo-helm";
          chart = "argo-cd";
          version = "10.5.0";
          targetNamespace = "argocd";
          valuesContent = toJSON {
            configs = {
              cm = {
                "accounts.github-actions" = "apiKey";
                "statusbadge.enabled" = true;
              };
              params = {
                "reposerver.enable.git.submodule" = "false";
              };
              rbac = {
                "policy.default" = "role:readonly";
                "policy.csv" = ''
                  p, github-actions, applications, *, ci/*, allow
                '';
              };
              secret.createSecret = false;
            };
            notifications = {
              secret.create = false; # We create it form an age-encrypted file ourselves further down
              notifiers."service.github" = toJSON {
                appID = "910267";
                installationID = "51398439";
                privateKey = "$github-privateKey";
              };
              templates."template.github" =
                let
                  argocdUrl = "https://argocd.nzbr.de";
                  appHealth = "{{ if and (eq .app.status.sync.status \"Healthy\") (eq .app.status.health.status \"Healthy\") }}success{{ else if or (eq .app.status.sync.status \"Degraded\") (eq .app.status.health.status \"Degraded\") }}failure{{ else }}pending{{ end }}";
                in
                toJSON {
                  github = {
                    repoURLPath = "{{.app.spec.source.repoURL}}";
                    revisionPath = "{{.app.status.operationState.syncResult.revision}}";
                    status = {
                      state = appHealth;
                      label = "ArgoCD/{{.app.metadata.name}}";
                      targetURL = "${argocdUrl}/applications/{{.app.metadata.name}}?operation=true";
                    };
                    deployment = {
                      state = appHealth;
                      environment = "{{.app.spec.source.targetRevision}}";
                      logURL = "${argocdUrl}/applications/{{.app.metadata.name}}?operation=true";
                      requiredContexts = [ ];
                      autoMerge = true;
                      transientEnvironment = false;
                      reference = "{{.app.spec.source.targetRevision}}";
                    };
                  };
              };
              triggers."trigger.on-status-change" = toJSON (
                flatten (
                  map
                    (status:
                      [
                        { send = [ "github" ]; when = "app.status.sync.status in ['${status}']"; }
                        { send = [ "github" ]; when = "app.status.health.status in ['${status}']"; }
                      ]
                    )
                    [ "Healthy" "Progressing" "Degraded" ]
                )
              );
            };
          };
        };
      };
      "02-argocd-notificatons-secret".source = config.nzbr.assets."k8s/argocd-notifications-secret.yaml";
      "03-argocd-approject-default".content = {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "AppProject";
        metadata = {
          namespace = "argocd";
          name = "default";
        };
        spec = {
          clusterResourceWhitelist = [
            { group = "*"; kind = "*"; }
          ];
          destinations = [
            { namespace = "*"; server = "*"; }
          ];
          sourceRepos = [
            "*"
          ];
        };
      };
      "03-argocd-approject-ci".content = {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "AppProject";
        metadata = {
          namespace = "argocd";
          name = "ci";
        };
        spec = {
          clusterResourceWhitelist = [
            {
              group = "*";
              kind = "*";
            }
          ];
          destinations = [
            {
              namespace = "*";
              server = "https://kubernetes.default.svc";
            }
          ];
          sourceRepos = [
            "*"
          ];
        };
      };
      # TODO: Move to VPN-Only
      "04-argocd-ingress".content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          namespace = "argocd";
          name = "argocd";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS";
          };
        };
        spec = {
          rules = [
            {
              host = "argocd.nzbr.de";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "argocd-server";
                        port = {
                          number = 443;
                        };
                      };
                    };
                  }
                ];
              };
            }
          ];
        };
      };
      "99-argocd-application-infrastructure".content = {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "Application";
        metadata = {
          namespace = "argocd";
          name = "infrastructure";
          annotations = {
            "notifications.argoproj.io/subscribe.on-status-change.github" = "";
          };
        };
        spec = {
          project = "default";
          source = {
            repoURL = "https://github.com/nzbr/infrastructure.git";
            path = "kubernetes";
            targetRevision = "main";
          };
          destination = {
            namespace = "default";
            server = "https://kubernetes.default.svc";
          };
          syncPolicy.automated = {
            prune = true;
            selfHeal = true;
          };
        };
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
      # amp.enable = true;
      audiobookshelf.enable = true;
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
      package = pkgs.postgresql_18;
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
      services = [ ];
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
        {
          name = "admin";
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
          id = 1;
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

  # cinder cron webhook
  systemd.services.cinder-webhook = rec {
    wants = [ "network-online.target" ];
    after = wants;
    path = [ pkgs.curl ];
    script = ''
      token="$(< "''${CREDENTIALS_DIRECTORY}/cinder-token")"
      printf 'header = "OAI-Sites-Authorization: Bearer %s"\n' "$token" |
        curl --config - --fail-with-body --silent --show-error \
          --connect-timeout 15 --max-time 840 \
          --json '{"action":"collect","args":{}}' \
          "https://cinder-briefing.arsoncopperflame.chatgpt.site/api/editor"
    '';
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = [ "cinder-token:${config.nzbr.assets."cinder.key"}" ];
      DynamicUser = true;
      TimeoutStartSec = "15min";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      UMask = "0077";
    };
  };
  systemd.timers.cinder-webhook = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:0/5:00";
      Persistent = true;
      AccuracySec = "10s";
    };
  };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}
