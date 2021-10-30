{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "ldap";
in {
  kubenix.deployment.openldap = {
    dependencies = [ "rook-ceph" ];
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
          storageClassName = "rook-ceph-block";
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
          namespace = "ldap";
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

      # ldap user manager (broken?)
      # {
      #   apiVersion = "apps/v1";
      #   kind = "Deployment";
      #   metadata = {
      #     labels = { "app.kubernetes.io/name" = "lum"; };
      #     name = "lum";
      #     namespace = "ldap";
      #   };
      #   spec = {
      #     replicas = 1;
      #     selector = { matchLabels = { "app.kubernetes.io/name" = "lum"; }; };
      #     template = {
      #       metadata = { labels = { "app.kubernetes.io/name" = "lum"; }; };
      #       spec = {
      #         containers = [{
      #           env = [
      #             {
      #               name = "SERVER_HOSTNAME";
      #               value = "account.nzbr.de";
      #             }
      #             {
      #               name = "LDAP_URI";
      #               value = "ldap://openldap.ldap.svc.kube";
      #             }
      #             {
      #               name = "LDAP_BASE_DN";
      #               value = "dc=nzbr,dc=de";
      #             }
      #             {
      #               name = "LDAP_REQUIRE_STARTTLS";
      #               value = "false";
      #             }
      #             {
      #               name = "LDAP_ADMINS_GROUP";
      #               value = "admins";
      #             }
      #             {
      #               name = "LDAP_USER_OU";
      #               value = "users";
      #             }
      #             {
      #               name = "LDAP_ADMIN_BIND_DN";
      #               value = "cn=admin,dc=nzbr,dc=de";
      #             }
      #             {
      #               name = "LDAP_ADMIN_BIND_PWD";
      #               valueFrom = {
      #                 secretKeyRef = {
      #                   key = "adminpassword";
      #                   name = "openldap";
      #                 };
      #               };
      #             }
      #             {
      #               name = "LDAP_USES_NIS_SCHEMA";
      #               value = "false";
      #             }
      #             {
      #               name = "EMAIL_DOMAIN";
      #               value = "nzbr.de";
      #             }
      #             {
      #               name = "NO_HTTPS";
      #               value = "true";
      #             }
      #           ];
      #           image = "docker.io/wheelybird/ldap-user-manager";
      #           imagePullPolicy = "Always";
      #           name = "lum";
      #           ports = [{
      #             containerPort = 80;
      #             name = "http";
      #           }];
      #         }];
      #       };
      #     };
      #   };
      # }
      # {
      #   apiVersion = "v1";
      #   kind = "Service";
      #   metadata = {
      #     labels = { "app.kubernetes.io/name" = "lum"; };
      #     name = "lum";
      #     namespace = "ldap";
      #   };
      #   spec = {
      #     ports = [{
      #       name = "http";
      #       port = 80;
      #       targetPort = "http";
      #     }];
      #     selector = { "app.kubernetes.io/name" = "lum"; };
      #     type = "ClusterIP";
      #   };
      # }
      # {
      #   apiVersion = "networking.k8s.io/v1beta1";
      #   kind = "Ingress";
      #   metadata = {
      #     annotations = {
      #       "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
      #       "kubernetes.io/ingress.class" = "nginx";
      #     };
      #     name = "lum";
      #     namespace = "ldap";
      #   };
      #   spec = {
      #     rules = [{
      #       host = "account.nzbr.de";
      #       http = {
      #         paths = [{
      #           backend = {
      #             serviceName = "lum";
      #             servicePort = 80;
      #           };
      #           path = "/";
      #         }];
      #       };
      #     }];
      #     tls = [{
      #       hosts = [ "account.nzbr.de" ];
      #       secretName = "account-nzbr-de";
      #     }];
      #   };
      # }
    ];
  };
}
