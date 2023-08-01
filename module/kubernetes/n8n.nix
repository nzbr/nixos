{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "n8n";
in
{
  nirgenx.deployment.n8n = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      (rec {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit namespace;
          name = "n8n";
          labels = {
            app = "n8n";
            component = "deployment";
          };
        };
        spec = {
          replicas = 1;
          selector.matchLabels = metadata.labels;
          template = {
            metadata.labels = metadata.labels;
            spec.containers = [rec {
              name = "n8n";
              image = "n8nio/n8n:latest";
              imagePullPolicy = "Always";
              ports = [{
                name = "http";
                containerPort = 5678;
              }];
              envFrom = [
                { configMapRef.name = "n8n-configmap"; }
                { secretRef.name = "n8n-secrets"; }
              ];
              livenessProbe.httpGet = {
                path = "/healthz";
                port = "http";
              };
              readinessProbe.httpGet = livenessProbe.httpGet;
            }];
          };
        };
      })

      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          inherit namespace;
          name = "n8n-configmap";
          labels = {
            app = "n8n";
            component = "configmap";
          };
        };
        data = {
          NODE_ENV = "production";
          GENERIC_TIMEZONE = "Europe/Berlin";
          N8N_PORT = "5678";
          WEBHOOK_URL = "https://n8n.nzbr.de";

          DB_TYPE = "postgresdb";
          DB_POSTGRESDB_HOST = "firestorm";
          DB_POSTGRESDB_DATABASE = "n8n";
          DB_POSTGRESDB_PORT = "5432";
          DB_POSTGRESDB_USER = "n8n";
        };
      }

      config.nzbr.assets."k8s/n8n-secret.yaml"

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "n8n";
          labels = {
            app = "n8n";
            component = "service";
          };
        };
        spec = {
          type = "ClusterIP";
          ports = [{
            name = "http";
            port = 80;
            targetPort = "http";
          }];
          selector = {
            app = "n8n";
            component = "deployment";
          };
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "n8n";
          annotations."kubernetes.io/ingress.class" = "nginx";
        };
        spec = {
          rules = [{
            host = "n8n.nzbr.de";
            http.paths = [{
              backend.service = {
                name = "n8n";
                port.name = "http";
              };
              path = "/";
              pathType = "Prefix";
            }];
          }];
        };
      }

    ];
  };
}
