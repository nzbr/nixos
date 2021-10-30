{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  kubenix.deployment.nextcloud = {
    dependencies = [ "keycloak" "nginx" ];
    steps = [
      {
        chart = {
          repository = "nextcloud";
          name = "nextcloud";
        };
        name = "nextcloud";
        namespace = "nextcloud";
        values = config.nzbr.assets."k8s/nextcloud-values.yaml";
      }
    ];
  };
}
