{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
{
  nirgenx.deployment.amp = {
    dependencies = [ "nginx" ];
    steps = [

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          namespace = "nginx";
          name = "redirect";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/configuration-snippet" = ''
              return 307 https://nzbr.link;
            '';
          };
        };
        spec = {
          rules = map
            (host: {
              inherit host;
              http = {
                paths = [{
                  backend.service = {
                    name = "nginx-ingress-nginx-controller";
                    port.number = 80;
                  };
                  path = "/";
                  pathType = "Prefix";
                }];
              };
            })
            [
              "nzbr.de"
              "go.nzbr.de"
            ];
        };
      }

    ];
  };
}
