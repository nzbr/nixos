{ config, lib, pkgs, ... }:
with builtins; with lib; {
  config =
    let
      cfg = config.kubenix;
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
                    [ "set -eux" ]
                    ++
                    map
                      (step:
                        if lib.types.helmInstallation.check step
                        then (
                          let
                            fileName = strings.sanitizeDerivationName "helm-chart-${step.chart}-${step.namespace}-${step.name}.json";
                            values = if isString step.values then step.values else pkgs.writeText fileName (toJSON step.values);
                          in
                          "${cfg.helmPackage}/bin/helm upgrade -i -n '${step.namespace}' --create-namespace -f '${values}' '${step.name}' '${step.chart}'"
                        )
                        else (
                          let
                            fileName = strings.sanitizeDerivationName "k8s${if step ? kind then "-${step.kind}" else ""}${if (step ? metadata) then "${if step.metadata ? name then "-${step.metadata.name}" else ""}${if step.metadata ? namespace then "-${step.metadata.namespace}" else ""}" else ""}.json";
                            resource = if isString step then step else pkgs.writeText fileName (toJSON step);
                          in
                          "${cfg.kubectlPackage}/bin/kubectl apply -f '${resource}'"
                        )
                      )
                      deployment.steps
                  );
                }
              )
          )
          cfg.deployment;
    };
}
