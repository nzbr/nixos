{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  host = "plex.nzbr.de";
  name = "plex";
  namespace = "plex";
  portName = "www";
in
{
  nirgenx.deployment.plex = {
    dependencies = [ "cert-manager" "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace name;
        };
        spec = {
          type = "ClusterIP";
          ports = [
            {
              protocol = "TCP";
              name = portName;
              port = 32400;
            }
          ];
        };
      }
      {
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          inherit namespace name;
        };
        subsets = [{
          addresses = [{
            ip = inputs.self.nixosConfigurations.earthquake.config.nzbr.nodeIp;
          }];
          ports = [
            {
              name = portName;
              port = 32400;
            }
          ];
        }];
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace name;
          annotations."kubernetes.io/ingress.class" = "nginx";
        };
        spec = {
          rules = [{
            inherit host;
            http.paths = [{
              backend.service = {
                inherit name;
                port.name = portName;
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
