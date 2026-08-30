{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  host = "plex.nzbr.de";
  name = "plex";
  namespace = "plex";
  port = 32400;
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
          type = "ExternalName";
          externalName = "vortex.dragon-augmented.ts.net";
        };
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
                port.number = port;
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
