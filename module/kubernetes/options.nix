{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.kubenix = with types;
    {
      enable = mkEnableOption "Kubernetes Deployments";
      waitForUnits = mkOption {
        type = listOf str;
        default = [ ];
        description = "A list of systemd units to wait for before performing the deployments";
        example = ''
          [ "network-online.target" "k3s.service" ];
        '';
      };
      kubeconfigPath = mkOption {
        type = oneOf [ path str ];
        default = "/root/.kube/config";
        description = "Path to the KUBECONFIG that should be used";
      };
      helmPackage = mkOption {
        type = package;
        default = pkgs.kubernetes-helm;
        description = "Helm package to use for deploying helm charts";
      };
      helmRepository = mkOption {
        type = attrsOf str;
        default = { };
        description = "Helm repositories that will be added";
        example = ''
          {
            bitnami = "https://charts.bitnami.com/bitnami";
          };
        '';
      };
      kubectlPackage = mkOption {
        type = package;
        default = pkgs.kubectl;
        description = "Kubectl package to use for kubectl apply";
      };
      deployment = mkOption {
        type = attrsOf kubernetesDeployment;
        default = { };
        description = "A set of kubernetes deployments that can be activated";
        example = ''
          {
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
          };
        '';
      };
    };
}
