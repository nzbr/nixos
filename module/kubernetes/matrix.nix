{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "matrix";
in
{
  nirgenx.deployment.matrix = {
    dependencies = [ "nginx" ];
    steps = [

      (kube.createNamespace namespace)

      {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "matrix";
        };
        spec = {
          type = "ClusterIP";
          ports = [
            {
              protocol = "TCP";
              name = "matrix";
              port = 8448;
            }
          ];
        };
      }

      {
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          inherit namespace;
          name = "matrix";
        };
        subsets = [{
          addresses = [{
            ip = inputs.self.nixosConfigurations.firestorm.config.nzbr.nodeIp;
          }];
          ports = [
            {
              name = "matrix";
              port = 28448;
            }
          ];
        }];
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "matrix";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          rules = map
            (host: {
              inherit host;
              http = {
                paths = map
                  (path: {
                    backend.service = {
                      name = "matrix";
                      port.name = "matrix";
                    };
                    inherit path;
                    pathType = "Prefix";
                  })
                  [
                    "/_matrix"
                    "/_synapse"
                  ];
              };
            })
            [
              "nzbr.de"
              "matrix.nzbr.de"
            ];
        };
      }

    ];
  };
}
