{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "ldap";
in
{
  kubenix.deployment.openldap = {
    dependencies = [ ];
    steps = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = namespace;
      }
      config.nzbr.assets."k8s/openldap-secret.yaml"
      {
        apiVersion = "v1";
        kind = "PersistentVolumeClaim";
        metadata = {
          name = "openldap-pvc";
          inherit namespace;
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "kadalu.pool";
          resources.requests.storage = "512M";
        };
      }
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          labels = { "app.kubernetes.io/name" = "openldap"; };
          name = "openldap";
          namespace = "ldap";
        };
        spec = {
          replicas = 1;
          selector = { matchLabels = { "app.kubernetes.io/name" = "openldap"; }; };
          template = {
            metadata = { labels = { "app.kubernetes.io/name" = "openldap"; }; };
            spec = {
              containers = [{
                env = [
                  {
                    name = "LDAP_ORGANISATION";
                    value = "nzbr.de";
                  }
                  {
                    name = "LDAP_DOMAIN";
                    value = "nzbr.de";
                  }
                  {
                    name = "LDAP_BASE_DN";
                    value = "dc=nzbr,dc=de";
                  }
                  {
                    name = "LDAP_RFC2307BIS_SCHEMA";
                    value = "true";
                  }
                  {
                    name = "LDAP_ADMIN_PASSWORD";
                    valueFrom = {
                      secretKeyRef = {
                        key = "adminpassword";
                        name = "openldap";
                      };
                    };
                  }
                ];
                image = "docker.io/osixia/openldap:latest";
                imagePullPolicy = "Always";
                name = "openldap";
                ports = [{
                  containerPort = 389;
                  name = "tcp-ldap";
                }];
                volumeMounts = [
                  {
                    mountPath = "/var/lib/ldap";
                    name = "vol";
                    subPath = "database";
                  }
                  {
                    mountPath = "/etc/ldap/slapd.d";
                    name = "vol";
                    subPath = "config";
                  }
                ];
              }];
              volumes = [{
                name = "vol";
                persistentVolumeClaim = { claimName = "openldap-pvc"; };
              }];
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          labels = { "app.kubernetes.io/name" = "openldap"; };
          name = "openldap";
          namespace = "ldap";
        };
        spec = {
          ports = [{
            name = "tcp-ldap";
            port = 389;
            targetPort = "tcp-ldap";
          }];
          selector = { "app.kubernetes.io/name" = "openldap"; };
          type = "ClusterIP";
        };
      }

      # phpldapadmin
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          labels = { "app.kubernetes.io/name" = "phpldapadmin"; };
          name = "phpldapadmin";
          namespace = "ldap";
        };
        spec = {
          replicas = 1;
          selector = {
            matchLabels = { "app.kubernetes.io/name" = "phpldapadmin"; };
          };
          template = {
            metadata = { labels = { "app.kubernetes.io/name" = "phpldapadmin"; }; };
            spec = {
              containers = [{
                env = [
                  {
                    name = "PHPLDAPADMIN_LDAP_HOSTS";
                    value = "openldap.ldap.svc.kube";
                  }
                  {
                    name = "PHPLDAPADMIN_HTTPS";
                    value = "false";
                  }
                ];
                image = "docker.io/osixia/phpldapadmin:latest";
                imagePullPolicy = "Always";
                name = "phpldapadmin";
                ports = [{
                  containerPort = 80;
                  name = "http";
                }];
              }];
            };
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          labels = { "app.kubernetes.io/name" = "phpldapadmin"; };
          name = "phpldapadmin";
          inherit namespace;
        };
        spec = {
          ports = [{
            name = "http";
            port = 80;
            targetPort = "http";
          }];
          selector = { "app.kubernetes.io/name" = "phpldapadmin"; };
          type = "ClusterIP";
        };
      }

      # stash backup
      (config.setupStashRepo config namespace)
      {
        apiVersion = "stash.appscode.com/v1beta1";
        kind = "BackupConfiguration";
        metadata = {
          inherit namespace;
          name = "ldap-backup";
        };
        spec = {
          repository.name = "wasabi-repo";
          schedule = "0 2 * * *";
          target = rec {
            ref = {
              apiVersion = "apps/v1";
              kind = "Deployment";
              name = "openldap";
            };
            volumeMounts = [
              {
                mountPath = "/var/lib/ldap";
                name = "vol";
                subPath = "database";
              }
              {
                mountPath = "/etc/ldap/slapd.d";
                name = "vol";
                subPath = "config";
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
    ];
  };
}
