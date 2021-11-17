{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.redis = {
    dependencies = [ "ceph-csi" ];
    steps = [
      {
        chart = {
          repository = "bitnami";
          name = "redis";
        };
        name = "redis";
        namespace = "redis";
        values = config.nzbr.assets."k8s/redis-values.yaml";
      }
    ];
  };
}
