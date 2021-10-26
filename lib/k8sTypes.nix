{ lib, ... }:
with builtins; with lib; {
  types = with types; {
    strOrPath = coercedTo path toString str;
    helmInstallation =
    let
      moduleConfig = submodule {
        options = {
          chart = mkOption {
            type = str;
            description = "The helm chart that will be installed";
            example = ''
              "bitnami/redis";
            '';
          };
          name = mkOption {
            type = str;
            description = "Name of the deployment";
            example = ''
              "redis";
            '';
          };
          namespace = mkOption {
            type = str;
            default = "default";
            description = "Namespace that the chart will be installed into. Will be created if it does not already exist";
            example = ''
              "redis";
            '';
          };
          values = mkOption {
            type = oneOf [ strOrPath (attrsOf anything) ];
            description = "Value definitions for the helm chart. This can be either an attrset or a path to a yaml/json that contains the values";
            example = ''
              {
                global = {
                  storageClass = "local-path";
                  redis.password = "hunter2";
                };
                cluster.enable = false;
              }
            '';
          };
        };
      };
    in
    addCheck moduleConfig (mod:
      mod ? chart && isString mod.chart
      && mod ? name && isString mod.name
      && mod ? namespace && isString mod.namespace
      && mod ? values && (isAttrs mod.values || isCoercibleToString mod.values)
    );
    kubernetesResource =
      (
        addCheck (attrsOf anything) # These apply to all k8s resources I can think of right not, this may need to be changed
        (val:
          val ? apiVersion && isString val.apiVersion
          && val ? kind && isString val.kind
        )
      ) // {
        description = "kubernetes resource definition";
      };
    kubernetesDeployment = submodule {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Enable this deployment";
        };
        steps = mkOption {
          type = listOf (oneOf [ strOrPath kubernetesResource helmInstallation ]);
          description = "A list of deployment steps. These can be either kubernetes resources (as a file or attrset) or helm charts";
        };
      };
    };
  };
}
