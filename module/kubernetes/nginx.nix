{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.nginx = {
    dependencies = [ "cert-manager" ];
    steps = [
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "nginx";
      }
      {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata.name = "wildcard-nzbr-de";
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
        namespace = "nginx";
        values.config = {
          hsts-preload = true;
          ssl-redirect = true;
          hostNetwork = true;
          extraArgs = [
            { default-ssl-certificate = "wildcard-nzbr-de"; }
          ];
        };
      }
    ];
  };
}
