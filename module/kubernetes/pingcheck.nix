{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "pingcheck";
  checks = {
    avalanche = {
      earthquake = "afe09796-a5f4-4859-9dd0-58b349eafaea";
      storm = "0ddd0e00-d57d-4452-bc48-413eaee94a33";
    };
    earthquake = {
      avalanche = "3344b2d3-d7ac-4780-b6d9-bc699baaaeb7";
      storm = "1d55330c-27ca-4ab3-bcf7-39425783e015";
    };
    storm = {
      avalanche = "df6f4c7d-ede8-4365-87a3-d16430fc8de0";
      earthquake = "6628d933-81ce-41f4-8fae-77087f27bb42";
    };
  };
in
{
  nirgenx.deployment.pingcheck = {
    steps = [

      (kube.createNamespace namespace)

    ] ++ (
      flatten (
        mapAttrsToList
          (host: targets:
            mapAttrsToList
              (target: hook-id: {
                apiVersion = "batch/v1";
                kind = "CronJob";
                metadata = {
                  inherit namespace;
                  name = "pingcheck-${host}-to-${target}";
                };
                spec = {
                  schedule = "*/10 * * * *";
                  successfulJobsHistoryLimit = 1;
                  failedJobsHistoryLimit = 1;
                  jobTemplate.spec.template.spec = {
                    nodeName = host;
                    restartPolicy = "Never";
                    containers = [{
                      name = "pingcheck";
                      image = "registry.gitlab.com/nzbr/pingcheck-container:main";
                      imagePullPolicy = "Always";
                      env = [
                        { name = "TARGET"; value = "${target}.nzbr.github.beta.tailscale.net"; }
                        { name = "WEBHOOK"; value = "https://hc-ping.com/${hook-id}"; }
                      ];
                    }];
                  };
                };
              })
              targets
          )
          checks
      )
    );
  };
}
