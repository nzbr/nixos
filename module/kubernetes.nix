{ config, lib, pkgs, ... }:
with builtins; with lib; {
  config =
    let
      cfg = config.nzbr.kubernetes;
      generateFileNameRes = resource: "k8s${if resource ? kind then "-${resource.kind}" else ""}${if (resource ? metadata) then "${if resource.metadata ? name then "-${resource.metadata.name}" else ""}${if resource.metadata ? namespace then "-${reource.metadata.namespace}" else ""}" else ""}.json";
    in
    mkIf cfg.enable {

      systemd.services =
        mapAttrs'
          (name: deployment:
            nameValuePair'
              "kubernetes-deployment-${name}"
              (
                mkIf deployment.enable rec {
                  requires = cfg.waitForUnits ++ [ "helm-repositories.service" ];
                  after = requires;
                  wantedBy = [ "multi-user.target" ];
                  environment = {
                    HOME = config.users.users.root.home;
                    KUBECONFIG = cfg.kubeconfigPath;
                  };
                  serviceConfig = {
                    Type = "oneshot";
                  };
                  script = concatStringsSep "\n" (
                    flatten (
                      map
                        (step:
                          if isString step
                          then [ "${cfg.kubectlPackage}/bin/kubectl apply -f ${step}" ]
                          else
                            (
                              if step ? helmChart
                              then (abort "Helm Charts are not implemented yet") # Helm Chart
                              else [ "${cfg.kubectlPackage}/bin/kubectl apply -f ${pkgs.writeText (generateFileNameRes step) (toJSON step)}" ]
                            )
                        )
                        deployment.steps
                    )
                  );
                }
              )
          )
          cfg.deployment;
    };
}
