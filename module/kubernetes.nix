{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.kubernetes = with types; {
    enable = mkEnableOption "Kubernetes Deployments";
  };

  config =
  let
    cfg = config.nzbr.kubernetes // {
      kubeconfigPath = "/run/kubeconfig";
      waitForUnits = [ "network-online.target" "k3s.service" ];
      helmPackage = pkgs.kubernetes-helm;
      helmRepository = {
        bitnami = "https://charts.bitnami.com/bitnami";
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
      };
    };
    generateFileNameRes = resource: "k8s${if resource ? kind then "-${resource.kind}" else ""}${if (resource ? metadata) then "${if resource.metadata ? name then "-${resource.metadata.name}" else ""}${if resource.metadata ? namespace then "-${reource.metadata.namespace}" else ""}" else ""}.json";
  in
  mkIf cfg.enable {

    systemd.services = {

      helm-repositories = rec {
        requires = cfg.waitForUnits;
        after = requires;
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOME = config.users.users.root.home;
          KUBECONFIG = cfg.kubeconfigPath;
        };
        serviceConfig = {
          Type = "oneshot";
        };
        script =
          concatStringsSep "\n" (
            (
              mapAttrsToList
              (name: url: "${cfg.helmPackage}/bin/helm repo add --force-update \"${name}\" \"${url}\"")
              cfg.helmRepository
            ) ++ [ "${cfg.helmPackage}/bin/helm repo update" ]
          );
      };

    }
    // (
      mapAttrs'
      (name: deployment:
        nameValuePair'
        "kubernetes-deployment-${name}"
        (
          mkIf deployment.enable rec {
            requires = cfg.waitForUnits ++ [ "helm-repositories.service" ];
            after = requires;
            wantedBy = [ "multi-user.target" ];
            environment = {
              HOME = config.users.users.root.home;
              KUBECONFIG = cfg.kubeconfigPath;
            };
            serviceConfig = {
              Type = "oneshot";
            };
            script = concatStringsSep "\n" (
              flatten (
                map
                (step:
                  if isString step
                  then [ "${cfg.kubectlPackage}/bin/kubectl apply -f ${step}" ]
                  else (
                    if step ? helmChart
                    then (abort "Helm Charts are not implemented yet") # Helm Chart
                    else ["${cfg.kubectlPackage}/bin/kubectl apply -f ${pkgs.writeText (generateFileNameRes step) (toJSON step)}"]
                  )
                )
                deployment.steps
              )
            );
          }
        )
      )
      cfg.deployment
    );

  };
}
