{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "amp";
in
{
  nirgenx.deployment.amp = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "amp";
        };
        spec = {
          type = "ClusterIP";
          ports = [
            {
              protocol = "TCP";
              name = "www";
              port = 80;
            }
            {
              protocol = "TCP";
              name = "minecraft";
              port = 25565;
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          inherit namespace;
          name = "amp";
        };
        subsets = [{
          addresses = [{
            ip = inputs.self.nixosConfigurations.avalanche.config.nzbr.nodeIp;
          }];
          ports = [
            {
              name = "www";
              port = 8080;
            }
            {
              name = "minecraft";
              port = 25560;
            }
          ];
        }];
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "amp";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          rules = [{
            host = "amp.nzbr.de";
            http = {
              paths = [{
                backend.service = {
                  name = "amp";
                  port.name = "www";
                };
                path = "/";
                pathType = "Prefix";
              }];
            };
          }];
          tls = [{
            hosts = [ "amp.nzbr.de" ];
          }];
        };
      }

    ];
  };

  nzbr.nginx.tcp-services = mkIf config.nirgenx.deployment.amp.enable {
    "25565" = "${namespace}/amp:25565";
  };
}
