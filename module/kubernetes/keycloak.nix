{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "keycloak";
in
{
  nirgenx.deployment.keycloak = {
    dependencies = [ "openldap" "nginx" ];
    steps = [
      (kube.createNamespace namespace)
      (config.nzbr.assets."k8s/keycloak-secret.yaml")
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
            spec = {
              containers = [{
                name = "keycloak";
                image = "quay.io/keycloak/keycloak:latest";
                imagePullPolicy = "Always";
                workingDir = "/opt/keycloak";
                command = [ "/opt/keycloak/bin/kc.sh" "start" "--auto-build" ];
                env = [
                  { name = "KEYCLOAK_ADMIN"; value = "admin"; }
                  { name = "KEYCLOAK_ADMIN_PASSWORD"; valueFrom.secretKeyRef = { key = "adminpassword"; name = "keycloak"; }; }
                  { name = "PROXY_ADDRESS_FORWARDING"; value = "true"; }
                  { name = "KC_PROXY"; value = "edge"; }
                  { name = "KC_HTTP_RELATIVE_PATH"; value = "/auth"; }
                  { name = "KC_DB"; value = "postgres"; }
                  { name = "KC_DB_URL"; value = "jdbc:postgresql://storm.nzbr.github.beta.tailscale.net/keycloak"; }
                  { name = "KC_DB_USER"; value = "keycloak"; }
                  { name = "KC_DB_PASSWORD"; valueFrom.secretKeyRef = { key = "postgrespassword"; name = "keycloak"; }; }
                  { name = "KC_HOSTNAME"; value = "sso.nzbr.de"; }
                ];
                ports = [
                  { name = "http"; containerPort = 8080; }
                  # { name = "https"; containerPort = 8443; }
                ];
                readinessProbe.httpGet = {
                  path = "/auth/realms/master";
                  port = 8080;
                };
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
        apiVersion = "networking.k8s.io/v1";
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
                backend.service = {
                  name = "keycloak";
                  port.number = 8080;
                };
                path = "/";
                pathType = "Prefix";
              }];
            };
          }];
        };
      }
    ];
  };
}
