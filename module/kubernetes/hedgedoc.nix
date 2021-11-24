{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  kubenix.deployment.hedgedoc = {
    dependencies = [ "keycloak" "nginx" ];
    steps = [
      (kube.installHelmChart "nicholaswilde" "hedgedoc" config.nzbr.assets."k8s/hedgedoc-values.yaml")
    ];
  };
}
