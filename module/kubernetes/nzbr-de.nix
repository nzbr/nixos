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
              return 307 https://twitter.com/_nzbr;
            '';
          };
        };
        spec = {
          rules = [{
            host = "nzbr.de";
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
          }];
        };
      }

    ];
  };
}
