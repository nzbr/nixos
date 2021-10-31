{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  kubenix.deployment.hedgedoc = {
    dependencies = [ "keycloak" "nginx" ];
    steps = [
      {
        chart = {
          repository = "nicholaswilde";
          name = "hedgedoc";
        };
        name = "hedgedoc";
        namespace = "hedgedoc";
        values = config.nzbr.assets."k8s/hedgedoc-values.yaml";
      }
    ];
  };
}
