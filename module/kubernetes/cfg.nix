{ config, lib, pkgs, ... }:
{
  config.nzbr.kubernetes = {
    kubeconfigPath = "/run/kubeconfig";
    waitForUnits = [ "network-online.target" "k3s.service" ];
    helmPackage = pkgs.kubernetes-helm;
    helmRepository = {
      bitnami = "https://charts.bitnami.com/bitnami";
      jetstack = "https://charts.jetstack.io";
      k8s-at-home = "https://k8s-at-home.com/charts/";
      nicholaswilde = "https://nicholaswilde.github.io/helm-charts";
    };
    kubectlPackage = pkgs.kubectl;
    deployment = {
      calico = {
        enable = true;
        steps = [
          "https://docs.projectcalico.org/manifests/tigera-operator.yaml"
          {
            apiVersion = "operator.tigera.io/v1";
            kind = "Installation";
            metadata = {
              name = "default";
            };
            spec = {
              calicoNetwork = {
                containerIPForwarding = "Enabled";
                ipPools = [
                  {
                    blockSize = 26;
                    cidr = "10.12.0.0/16";
                    encapsulation = "IPIP";
                    natOutgoing = "Enabled";
                    nodeSelector = "all()";
                  }
                ];
              };
            };
          }
        ];
      };
      cert-manager = {
        enable = true;
        steps = [
          {
            chart = "jetstack/cert-manager";
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
    };
  };
}
