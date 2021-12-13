{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.deployment.cert-manager = {
    steps = [
      (kube.installHelmChart "jetstack" "cert-manager" { installCRDs = true; })
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
      (config.nzbr.assets."k8s/cert-manager-letsencrypt-config.yaml")
    ];
  };
}
