{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.deployment.cert-manager = {
    enable = mkDefault false;
    steps = [
      {
        chart = {
          repository = "jetstack";
          name = "cert-manager";
        };
        name = "cert-manager";
        namespace = "cert-manager";
        values = {
          installCRDs = true;
        };
      }
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "cert-manager";
          labels = {
            "certmanager.k8s.io/disable-validation" = "true";
          };
        };
      }
      config.nzbr.assets."k8s/cert-manager-letsencrypt-config.yaml"
    ];
  };
}
