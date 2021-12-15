{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.vaultwarden =
    {
      dependencies = [ "nginx" "stash" "kadalu" ];
      steps = [
        (kube.installHelmChart "k8s-at-home" "vaultwarden" config.nzbr.assets."k8s/vaultwarden-values.yaml")

        # stash backup
        (config.setupStashRepo "vaultwarden")
        {
          apiVersion = "stash.appscode.com/v1beta1";
          kind = "BackupConfiguration";
          metadata = {
            namespace = "vaultwarden";
            name = "vaultwarden-backup";
          };
          spec = {
            repository.name = "wasabi-repo";
            schedule = "0 2 * * *";
            target = rec {
              ref = {
                apiVersion = "apps/v1";
                kind = "Deployment";
                name = "vaultwarden";
              };
              volumeMounts = [
                {
                  mountPath = "/config";
                  name = "config";
                  subPath = "database";
                }
              ];
              paths = map (x: x.mountPath) volumeMounts;
            };
            runtimeSettings.container.securityContext = {
              runAsUser = 0;
              runAsGroup = 0;
            };
            retentionPolicy = {
              name = "last-year";
              keepDaily = 7;
              keepWeekly = 4;
              keepMonthly = 12;
              prune = true;
            };
          };
        }
      ];
    };
}
