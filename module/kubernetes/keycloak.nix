{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "keycloak";
in {
  kubenix.deployment.keycloak = {
    dependencies = [ "openldap" "nginx" ];
    steps = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = namespace;
      }
      config.nzbr.assets."k8s/keycloak-secret.yaml"
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit namespace;
          name = "keycloak";
          labels.app = "keycloak";
        };
        spec = {
          replicas = 1;
          selector.matchLabels.app = "keycloak";
          template = {
            metadata.labels.app = "keycloak";
            spec.containers = [{
              name = "keycloak";
              image = "quay.io/keycloak/keycloak:latest";
              imagePullPolicy = "Always";
              env = [
                { name = "KEYCLOAK_USER"; value = "admin"; }
                { name = "KEYCLOAK_PASSWORD"; valueFrom.secretKeyRef = { key = "adminpassword"; name = "keycloak"; }; }
                { name = "PROXY_ADDRESS_FORWARDING"; value = "true"; }
                { name = "DB_VENDOR"; value = "postgres"; }
                { name = "DB_ADDR"; value = "storm.nzbr.github.beta.tailscale.net"; }
                { name = "DB_DATABASE"; value = "keycloak"; }
                { name = "DB_USER"; value = "keycloak"; }
                { name = "DB_PASSWORD"; valueFrom.secretKeyRef = { key = "postgrespassword"; name = "keycloak"; }; }
              ];
              ports = [
                { name = "http"; containerPort = 8080; }
                { name = "https"; containerPort = 8443; }
              ];
              readinessProbe.httpGet = {
                path = "/auth/realms/master";
                port = 8080;
              };
            }];
          };
        };
      }
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "keycloak";
          labels.app = "keycloak";
        };
        spec = {
          ports = [{
            name = "http";
            port = 8080;
            targetPort = 8080;
          }];
          selector.app = "keycloak";
          type = "ClusterIP";
        };
      }
      {
        apiVersion = "networking.k8s.io/v1beta1";
        kind = "Ingress";
        metadata = {
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
            "kubernetes.io/ingress.class" = "nginx";
          };
          name = "keycloak";
          namespace = "keycloak";
        };
        spec = {
          rules = [{
            host = "sso.nzbr.de";
            http = {
              paths = [{
                backend = {
                  serviceName = "keycloak";
                  servicePort = 8080;
                };
                path = "/";
              }];
            };
          }];
          tls = [{
            hosts = [ "sso.nzbr.de" ];
          }];
        };
      }
    ];
  };
}