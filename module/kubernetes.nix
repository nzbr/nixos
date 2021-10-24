{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.kubernetes = with types; {
    enable = mkEnableOption "Kubernetes Deployments";
  };

  config =
  let
    cfg = config.nzbr.kubernetes // {
      kubeconfigPath = "/run/kubeconfig";
      waitForUnits = [ "k3s.service" ];
      helmPackage = pkgs.kubernetes-helm;
      helmRepository = {
        bitnami = "https://charts.bitnami.com/bitnami";
        k8s-at-home = "https://k8s-at-home.com/charts/";
        nicholaswilde = "https://nicholaswilde.github.io/helm-charts";
      };
    };
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

    };

  };
}
