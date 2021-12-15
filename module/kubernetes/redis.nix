{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.redis = {
    dependencies = [ "stash" "kadalu" ];
    steps = [
      (kube.installHelmChart "bitnami" "redis" config.nzbr.assets."k8s/redis-values.yaml")

      # stash backup
      (config.setupStashRepo "redis")
      {
        apiVersion = "stash.appscode.com/v1beta1";
        kind = "BackupConfiguration";
        metadata = {
          namespace = "redis";
          name = "redis-master-backup";
        };
        spec = {
          repository.name = "wasabi-repo";
          schedule = "0 2 * * *";
          target = {
            ref = {
              apiVersion = "apps/v1";
              kind = "StatefulSet";
              name = "redis-master";
            };
            volumeMounts = [{
              name = "redis-data";
              mountPath = "/data";
            }];
            paths = [
              "/data"
            ];
          };
          retentionPolicy = {
            name = "last-4-weeks";
            keepDaily = 7;
            keepWeekly = 4;
            prune = true;
          };
        };
      }
    ];
  };
}
