{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.nginx = {
    dependencies = [ "cert-manager" ];
    steps = [
      {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata.name = "wildcard-nzbr-de";
        metadata.namespace = "default";
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
        values.controller = {
          config = {
            hsts-preload = true;
            ssl-redirect = true;
          };
          extraArgs = {
            default-ssl-certificate = "default/wildcard-nzbr-de";
          };
        };
      }
    ];
  };
}
