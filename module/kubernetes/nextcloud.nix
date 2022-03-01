{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  nirgenx.deployment.nextcloud = {
    dependencies = [ "keycloak" "nginx" ];
    steps = [
      (kube.installHelmChart "nextcloud" "nextcloud" config.nzbr.assets."k8s/nextcloud-values.yaml")
    ];
  };
}
