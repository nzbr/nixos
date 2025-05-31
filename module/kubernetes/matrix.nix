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
        kind = "Service";
        metadata = {
          inherit namespace;
          name = "matrix-sliding-sync";
        };
        spec = {
          type = "ClusterIP";
          ports = [
            {
              protocol = "TCP";
              name = "sliding-sync";
              port = 8009;
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
        apiVersion = "v1";
        kind = "Endpoints";
        metadata = {
          inherit namespace;
          name = "matrix-sliding-sync";
        };
        subsets = [{
          addresses = [{
            ip = inputs.self.nixosConfigurations.firestorm.config.nzbr.nodeIp;
          }];
          ports = [
            {
              name = "sliding-sync";
              port = 8009;
            }
          ];
        }];
      }

      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          inherit namespace;
          name = "matrix-headers";
        };
        data = {
          # Traffic to the server is routed through earthquake's private IP in the home network
          "access-control-allow-private-network" = "true";
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "matrix";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/proxy-body-size" = "200M";
            "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300";
            "nginx.ingress.kubernetes.io/custom-headers" = "${namespace}/matrix-headers";
          };
        };
        spec = {
          rules = map
            (host:
              {
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
              }
            )
            [
              "nzbr.de"
              "matrix.nzbr.de"
            ];
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "matrix-sliding-sync";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/proxy-body-size" = "200M";
            "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300";
            "nginx.ingress.kubernetes.io/custom-headers" = "${namespace}/matrix-headers";
          };
        };
        spec = {
          rules = [
            {
              host = "matrix.nzbr.de";
              http = {
                paths = map
                  (path: {
                    backend.service = {
                      name = "matrix-sliding-sync";
                      port.name = "sliding-sync";
                    };
                    inherit path;
                    pathType = "Prefix";
                  })
                  [
                    "/client"
                    "/_matrix/client/unstable/org.matrix.msc3575/sync"
                  ];
              };
            }
          ];
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "matrix-well-known";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/proxy-body-size" = "200M";
            "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300";
            "nginx.ingress.kubernetes.io/custom-headers" = "${namespace}/matrix-headers";
            "nginx.ingress.kubernetes.io/configuration-snippet" = ''
              default_type application/json;
              return 200 '{ "m.homeserver": { "base_url": "https://matrix.nzbr.de" }, "org.matrix.msc3575.proxy": { "url": "https://matrix.nzbr.de" } }';
            '';
          };
        };
        spec = {
          rules = map
            (host:
              {
                inherit host;
                http = {
                  paths = map
                    (path: {
                      backend.service = {
                        name = "matrix-sliding-sync";
                        port.name = "sliding-sync";
                      };
                      inherit path;
                      pathType = "Prefix";
                    })
                    [
                      "/.well-known/matrix/client"
                    ];
                };
              }
            )
            [
              "nzbr.de"
              "matrix.nzbr.de"
            ];
        };
      }


    ];
  };
}
