{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.vaultwarden =
    let
      namespace = "vaultwarden";
    in
    {
      dependencies = [ "nginx" "stash" ]; # TODO: kadalu
      steps = [
        {
          chart = {
            repository = "k8s-at-home";
            name = "vaultwarden";
          };
          name = "vaultwarden";
          inherit namespace;
          values = config.nzbr.assets."k8s/vaultwarden-values.yaml";
        }

        # stash backup
        (config.setupStashRepo namespace)
        {
          apiVersion = "stash.appscode.com/v1beta1";
          kind = "BackupConfiguration";
          metadata = {
            inherit namespace;
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
