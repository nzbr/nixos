{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  options.nzbr.nginx.tcp-services = mkOption {
    description = "TCP Services";
    type = with types; attrsOf str;
    default = { };
  };

  config =
    let
      namespace = "nginx";
    in
    {
      nirgenx.deployment.nginx = {
        dependencies = [ "cert-manager" ];
        steps = [

          (kube.createNamespace namespace)

          {
            apiVersion = "cert-manager.io/v1";
            kind = "Certificate";
            metadata = {
              name = "wildcard-nzbr-de";
              inherit namespace;
            };
            spec = {
              secretName = "wildcard-nzbr-de";
              dnsNames = [
                "nzbr.de"
                "*.nzbr.de"
              ];
              issuerRef = {
                name = "letsencrypt-prod";
                kind = "ClusterIssuer";
                group = "cert-manager.io";
              };
            };
          }

          {
            chart = {
              repository = "ingress-nginx";
              name = "ingress-nginx";
            };
            name = "nginx";
            inherit namespace;
            values = {
              controller = {
                config = {
                  hsts-preload = true;
                  ssl-redirect = true;
                  access-log-path = "/dev/null";
                };
                extraArgs = {
                  default-ssl-certificate = "${namespace}/wildcard-nzbr-de";
                };
              };
              tcp = config.nzbr.nginx.tcp-services;
            };
          }

          # TODO: Delete Certificate default/wildcard-nzbr-de

        ];
      };

      nzbr.nginx.tcp-services = {
        "8448" = "${namespace}/nginx-ingress-nginx-controller:443";
      };
    };
}
