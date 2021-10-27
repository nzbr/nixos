{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.helmRepository = mkIf config.kubenix.enable {
    bitnami = "https://charts.bitnami.com/bitnami";
    jetstack = "https://charts.jetstack.io";
    k8s-at-home = "https://k8s-at-home.com/charts/";
    nicholaswilde = "https://nicholaswilde.github.io/helm-charts";
  };
}
