{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "birdsite";
  fromSecret = key: {
    secretKeyRef = {
      name = "birdsite";
      inherit key;
    };
  };
in
{
  nirgenx.deployment.birdsite = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      config.nzbr.assets."k8s/birdsite-secret.yaml"

      rec {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit namespace;
          name = "birdsite";
          labels = { "app.kubernetes.io/name" = "birdsite"; };
        };
        spec = {
          replicas = 1;
          selector = { matchLabels = metadata.labels; };
          template = {
            metadata = { labels = metadata.labels; };
            spec.containers = [{
              name = "birdsite";
              image = "docker.io/nicolasconstant/birdsitelive:latest";
              imagePullPolicy = "Always";
              env = [
                { name = "Instance__Domain"; value = "bird.nzbr.de"; }
                { name = "Instance__AdminEmail"; value = "bird" + "@" + "nzbr.de"; }
                { name = "Instance__PublishReplies"; value = "true"; }
                { name = "Db__Type"; value = "postgres"; }
                { name = "Db__Host"; value = "storm.nzbr.github.beta.tailscale.net"; }
                { name = "Db__Name"; value = "birdsite"; }
                { name = "Db__User"; value = "birdsite"; }
                { name = "Db__Password"; valueFrom = fromSecret "dbpass"; }
                { name = "Twitter__ConsumerKey"; valueFrom = fromSecret "apikey"; }
                { name = "Twitter__ConsumerSecret"; valueFrom = fromSecret "apisecret"; }
                { name = "Moderation__FollowersWhiteListing"; valueFrom = fromSecret "allowlist"; }
                { name = "Instance__PublishReplies"; value = "true"; }
                { name = "Instance__SensitiveTwitterAccounts"; valueFrom = fromSecret "sensitiveAccounts"; }
                # { name = "Logging__LogLevel__Default"; value = "Trace"; }
                # { name = "Logging__LogLevel__ApplicationInsights__Default"; value = "Trace"; }
              ];
              ports = [{
                containerPort = 80;
                name = "www";
              }];
            }];
          };
        };
      }

      rec {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "birdsite";
          labels = { "app.kubernetes.io/name" = "birdsite"; };
        };
        spec = {
          selector = metadata.labels;
          type = "ClusterIP";
          ports = [{
            name = "www";
            port = 80;
            targetPort = "www";
          }];
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "birdsite";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          rules = [{
            host = "bird.nzbr.de";
            http = {
              paths = [{
                backend.service = {
                  name = "birdsite";
                  port.name = "www";
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
