{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "audiobookshelf";
in
{
  nirgenx.deployment.audiobookshelf = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "audiobookshelf";
        };
        spec = {
          type = "ClusterIP";
          ports = [
            {
              protocol = "TCP";
              name = "www";
              port = inputs.self.nixosConfigurations.earthquake.config.services.audiobookshelf.port;
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          inherit namespace;
          name = "audiobookshelf";
        };
        subsets = [{
          addresses = [{
            ip = inputs.self.nixosConfigurations.earthquake.config.nzbr.nodeIp;
          }];
          ports = [
            {
              name = "www";
              port = inputs.self.nixosConfigurations.earthquake.config.services.audiobookshelf.port;
            }
          ];
        }];
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "audiobookshelf";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          rules = [{
            host = "abs.nzbr.de";
            http = {
              paths = [{
                backend.service = {
                  name = "audiobookshelf";
                  port.name = "www";
                };
                path = "/";
                pathType = "Prefix";
              }];
            };
          }];
          tls = [{
            hosts = [ "abs.nzbr.de" ];
          }];
        };
      }

    ];
  };

}
