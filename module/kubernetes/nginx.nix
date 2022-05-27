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
                  custom-http-errors = "400,401,403,404,405,408,409,410,411,412,413,414,415,418,429,500,501,502,503,504";
                };
                extraArgs = {
                  default-ssl-certificate = "${namespace}/wildcard-nzbr-de";
                };
              };
              defaultBackend = {
                enabled = true;
                name = "custom-default-backend";
                image = {
                  repository = "ghcr.io/nzbr/nzbr/bluescreen-errorpages";
                  tag = "latest";
                  pullPolicy = "Always";
                  readOnlyRootFilesystem = false;
                };
                port = "8080";
                # extraVolumes = [
                #   { name = "tmp"; emptyDir = {}; }
                #   { name = "cache"; emptyDir = {}; }
                #   { name = "run"; emptyDir = {}; }
                # ];
                # extraVolumeMounts = [
                #   { name = "tmp"; mountPath = "/tmp"; }
                #   { name = "cache"; mountPath = "/var/cache"; }
                #   { name = "run"; mountPath = "/var/run"; }
                # ];
              };
              tcp = config.nzbr.nginx.tcp-services;
            };
          }

        ];
      };

      nzbr.nginx.tcp-services = {
        "8448" = "${namespace}/nginx-ingress-nginx-controller:443";
      };
    };
}
