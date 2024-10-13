{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "vaultwarden";
in
{
  nirgenx.deployment.vaultwarden =
    {
      dependencies = [ "nginx" "stash" "kadalu" ];
      steps = [

        (config.nzbr.assets."k8s/vaultwarden-secret.yaml")

        {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            inherit namespace;
            name = "vaultwarden-config";
            labels = {
              "app.kubernetes.io/instance" = "vaultwarden";
              "app.kubernetes.io/managed-by" = "Helm";
              "app.kubernetes.io/name" = "vaultwarden";
            };
          };
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            resources = { requests = { storage = "1Gi"; }; };
            storageClassName = "kadalu.pool";
          };
        }

        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            inherit namespace;
            name = "vaultwarden";
            labels = {
              "app.kubernetes.io/instance" = "vaultwarden";
              "app.kubernetes.io/managed-by" = "Helm";
              "app.kubernetes.io/name" = "vaultwarden";
            };
          };
          spec = {
            replicas = 1;
            revisionHistoryLimit = 3;
            selector = {
              matchLabels = {
                "app.kubernetes.io/instance" = "vaultwarden";
                "app.kubernetes.io/name" = "vaultwarden";
              };
            };
            strategy = { type = "Recreate"; };
            template = {
              metadata = {
                labels = {
                  "app.kubernetes.io/instance" = "vaultwarden";
                  "app.kubernetes.io/name" = "vaultwarden";
                };
              };
              spec = {
                automountServiceAccountToken = true;
                containers = [{
                  env = [
                    {
                      name = "DATA_FOLDER";
                      value = "config";
                    }
                    {
                      name = "SIGNUPS_ALLOWED";
                      value = "false";
                    }
                    {
                      name = "SIGNUPS_VERIFY";
                      value = "true";
                    }
                  ];
                  envFrom = [{ secretRef.name = "vaultwarden-secret"; }];
                  image = "vaultwarden/server:1.32.2-alpine";
                  imagePullPolicy = "IfNotPresent";
                  livenessProbe = {
                    failureThreshold = 3;
                    initialDelaySeconds = 0;
                    periodSeconds = 10;
                    tcpSocket = { port = 80; };
                    timeoutSeconds = 1;
                  };
                  name = "vaultwarden";
                  ports = [
                    {
                      containerPort = 80;
                      name = "http";
                      protocol = "TCP";
                    }
                  ];
                  readinessProbe = {
                    failureThreshold = 3;
                    initialDelaySeconds = 0;
                    periodSeconds = 10;
                    tcpSocket = { port = 80; };
                    timeoutSeconds = 1;
                  };
                  startupProbe = {
                    failureThreshold = 30;
                    initialDelaySeconds = 0;
                    periodSeconds = 5;
                    tcpSocket = { port = 80; };
                    timeoutSeconds = 1;
                  };
                  volumeMounts = [{
                    mountPath = "/config";
                    name = "config";
                  }];
                }];
                dnsPolicy = "ClusterFirst";
                enableServiceLinks = true;
                serviceAccountName = "default";
                volumes = [{
                  name = "config";
                  persistentVolumeClaim = { claimName = "vaultwarden-config"; };
                }];
              };
            };
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            name = "vaultwarden";
            labels = {
              "app.kubernetes.io/instance" = "vaultwarden";
              "app.kubernetes.io/managed-by" = "Helm";
              "app.kubernetes.io/name" = "vaultwarden";
            };
          };
          spec = {
            ports = [
              {
                name = "http";
                port = 80;
                protocol = "TCP";
                targetPort = "http";
              }
            ];
            selector = {
              "app.kubernetes.io/instance" = "vaultwarden";
              "app.kubernetes.io/name" = "vaultwarden";
            };
            type = "ClusterIP";
          };
        }

        {
          apiVersion = "networking.k8s.io/v1";
          kind = "Ingress";
          metadata = {
            inherit namespace;
            name = "vaultwarden";
            annotations = { "cert-manager.io/cluster-issuer" = "letsencrypt-prod"; };
            labels = {
              "app.kubernetes.io/instance" = "vaultwarden";
              "app.kubernetes.io/managed-by" = "Helm";
              "app.kubernetes.io/name" = "vaultwarden";
            };
          };
          spec = {
            ingressClassName = "nginx";
            rules = [{
              host = "vault.nzbr.de";
              http = {
                paths = [{
                  backend = {
                    service = {
                      name = "vaultwarden";
                      port = { number = 80; };
                    };
                  };
                  path = "/";
                  pathType = "Prefix";
                }];
              };
            }];
            tls = [{ hosts = [ "vault.nzbr.de" ]; }];
          };
        }

        # stash backup
        (config.setupStashRepo namespace)
        {
          apiVersion = "stash.appscode.com/v1beta1";
          kind = "BackupConfiguration";
          metadata = {
            inherit namespace;
            name = "vaultwarden-backup";
          };
          spec = {
            repository.name = "wasabi-repo";
            schedule = "0 2 * * *";
            target = rec {
              ref = {
                apiVersion = "apps/v1";
                kind = "Deployment";
                name = "vaultwarden";
              };
              volumeMounts = [
                {
                  mountPath = "/config";
                  name = "config";
                  subPath = "database";
                }
              ];
              paths = map (x: x.mountPath) volumeMounts;
            };
            runtimeSettings.container.securityContext = {
              runAsUser = 0;
              runAsGroup = 0;
            };
            retentionPolicy = {
              name = "last-year";
              keepDaily = 7;
              keepWeekly = 4;
              keepMonthly = 12;
              prune = true;
            };
          };
        }

        # # stash restore
        # {
        #   apiVersion = "stash.appscode.com/v1beta1";
        #   kind = "RestoreSession";
        #   metadata = {
        #     inherit namespace;
        #     name = "vaultwarden-restore";
        #   };
        #   spec = {
        #     repository.name = "wasabi-repo";
        #     target = rec {
        #       ref = {
        #         apiVersion = "apps/v1";
        #         kind = "Deployment";
        #         name = "vaultwarden";
        #       };
        #       volumeMounts = [
        #         {
        #           mountPath = "/config";
        #           name = "config";
        #           subPath = "database";
        #         }
        #       ];
        #     };
        #     runtimeSettings.container.securityContext = {
        #       runAsUser = 0;
        #       runAsGroup = 0;
        #     };
        #   };
        # }

      ];
    };
}
