{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "plausible";
in
{
  nirgenx.deployment.plausible = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      # Clickhouse Database

      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          inherit namespace;
          name = "clickhouse";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "kadalu.pool";
          resources.requests.storage = "5G";
        };
      }

      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          inherit namespace;
          name = "clickhouse-config";
          labels = {
            app = "plausible";
            component = "clickhouse";
          };
        };
        data = {
          config = ''
            <clickhouse>
              <listen_host>0.0.0.0</listen_host>
              <logger>
                <level>information</level>
                <console>true</console>
              </logger>

              <!-- Stop all the unnecessary logging -->
              <query_thread_log remove="remove"/>
              <query_log remove="remove"/>
              <text_log remove="remove"/>
              <trace_log remove="remove"/>
              <metric_log remove="remove"/>
              <asynchronous_metric_log remove="remove"/>
              <session_log remove="remove"/>
              <part_log remove="remove"/>
            </clickhouse>
          '';
          userConfig = ''
            <clickhouse>
              <profiles>
                <default>
                  <log_queries>0</log_queries>
                  <log_query_threads>0</log_query_threads>
                </default>
              </profiles>
            </clickhouse>
          '';
        };
      }

      (rec {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit namespace;
          name = "clickhouse";
          labels = {
            app = "plausible";
            component = "clickhouse";
          };
        };
        spec = {
          replicas = 1;
          selector.matchLabels = metadata.labels;
          template = {
            metadata.labels = metadata.labels;
            spec = {
              affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution = [{
                podAffinityTerm = {
                  labelSelector.matchExpressions = [{
                    key = "component";
                    operator = "In";
                    values = [ "web" ];
                  }];
                  topologyKey = "kubernetes.io/hostname";
                };
                weight = 100;
              }];
              containers = [{
                name = "clickhouse";
                image = "clickhouse/clickhouse-server:23.9.2.56-alpine";
                ports = [{
                  name = "http";
                  containerPort = 8123;
                }];
                volumeMounts = [
                  { name = "data"; mountPath = "/var/lib/clickhouse"; }
                  {
                    name = "config";
                    mountPath = "/etc/clickhouse-server/config.d";
                    subPath = "config.d";
                  }
                  {
                    name = "config";
                    mountPath = "/etc/clickhouse-server/users.d";
                    subPath = "users.d";
                  }
                ];
              }];
              volumes = [
                { name = "data"; persistentVolumeClaim.claimName = "clickhouse"; }
                {
                  name = "config";
                  configMap = {
                    name = "clickhouse-config";
                    items = [
                      { key = "config"; path = "config.d/logging.xml"; }
                      { key = "userConfig"; path = "users.d/logging.xml"; }
                    ];
                  };
                }
              ];
            };
          };
        };
      })

      (rec {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          labels = {
            app = "plausible";
            component = "clickhouse";
          };
          name = "clickhouse";
          inherit namespace;
        };
        spec = {
          ports = [{
            name = "http";
            port = 80;
            targetPort = "http";
          }];
          selector = metadata.labels;
          type = "ClusterIP";
        };
      })

      # Plausible Analytics

      (config.nzbr.assets."k8s/plausible-secret.yaml")

      (rec {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit namespace;
          name = "plausible";
          labels = {
            app = "plausible";
            component = "web";
          };
        };
        spec = {
          replicas = 1;
          selector.matchLabels = metadata.labels;
          template = {
            metadata.labels = metadata.labels;
            spec = {
              affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution = [{
                podAffinityTerm = {
                  labelSelector.matchExpressions = [{
                    key = "component";
                    operator = "In";
                    values = [ "clickhouse" ];
                  }];
                  topologyKey = "kubernetes.io/hostname";
                };
                weight = 100;
              }];
              containers = [{
                name = "plausible";
                image = "plausible/analytics:v2.0";
                command = [ "sh" "-c" "/entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run" ];
                ports = [{
                  name = "http";
                  containerPort = 8000;
                }];
                envFrom = [{ secretRef.name = "plausible-secret"; }];
              }];
            };
          };
        };
      })

      (rec {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          labels = {
            app = "plausible";
            component = "web";
          };
          name = "plausible";
          inherit namespace;
        };
        spec = {
          ports = [{
            name = "http";
            port = 80;
            targetPort = "http";
          }];
          selector = metadata.labels;
          type = "ClusterIP";
        };
      })

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "plausible";
          annotations."kubernetes.io/ingress.class" = "nginx";
        };
        spec = {
          rules = [{
            host = "stats.nzbr.de";
            http.paths = [{
              backend.service = {
                name = "plausible";
                port.name = "http";
              };
              path = "/";
              pathType = "Prefix";
            }];
          }];
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "plausible-event";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          rules = map
            (host: {
              inherit host;
              http = {
                paths = [{
                  backend.service = {
                    name = "plausible";
                    port.name = "http";
                  };
                  path = "/api/event";
                  pathType = "Exact";
                }];
              };
            })
            [ "nzbr.link" ];
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "plausible-scripts";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/rewrite-target" = "/js/$2";
          };
        };
        spec = {
          rules = map
            (host: {
              inherit host;
              http = {
                paths = [{
                  backend.service = {
                    name = "plausible";
                    port.name = "http";
                  };
                  path = "/js/plausible(/|$)(.*)";
                  pathType = "Prefix";
                }];
              };
            })
            [ "nzbr.link" ];
        };
      }

      # Stash Backup

      (config.setupStashRepo namespace)

      {
        apiVersion = "stash.appscode.com/v1beta1";
        kind = "BackupConfiguration";
        metadata = {
          inherit namespace;
          name = "clickhouse-backup";
        };
        spec = {
          repository.name = "wasabi-repo";
          schedule = "0 2 * * *";
          target = rec {
            ref = {
              apiVersion = "apps/v1";
              kind = "Deployment";
              name = "clickhouse";
            };
            volumeMounts = [{ name = "data"; mountPath = "/var/lib/clickhouse"; }];
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

    ];
  };
}
