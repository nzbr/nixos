{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  options = with types; {
    setupStashRepo = mkOption {
      type = functionTo anything;
    };
  };

  config = {
    setupStashRepo = config: namespace:
      let
        repository = pkgs.writeText "stash-repository-${namespace}.yaml"
          (toJSON {
            apiVersion = "stash.appscode.com/v1alpha1";
            kind = "Repository";
            metadata = {
              name = "wasabi-repo";
            };
            spec = {
              backend = {
                s3 = {
                  bucket = "stash-nzbr";
                  endpoint = "s3.eu-central-1.wasabisys.com";
                  prefix = "/${namespace}";
                };
                storageSecretName = "wasabi-secret";
              };
            };
          });
      in
      {
        script = ''
          ${pkgs.kubectl}/bin/kubectl -n ${namespace} apply -f ${config.nzbr.assets."k8s/stash-repo-wasabi.yaml"}
          ${pkgs.kubectl}/bin/kubectl -n ${namespace} apply -f ${repository}
        '';
      };

    kubenix.deployment.stash =
      let
        tokenPath = "/tmp/stash-token.json";
        valuesPath = "/run/stash-values.json";
        values = pkgs.writeText "values.json" ''
          {
            "features": {
              "community": true
            }
          }
        '';
      in
      {
        dependencies = [ ];
        steps = [
          {
            script = ''
              source ${config.nzbr.assets."k8s/stash-license-variables.env"}
              CLUSTER=$(${pkgs.kubectl}/bin/kubectl get ns kube-system -o=jsonpath='{.metadata.uid}')
              ${pkgs.curl}/bin/curl -X POST -d "name=$NAME&email=$EMAIL&product=stash-community&cluster=$CLUSTER&tos=true&token=$TOKEN" https://license-issuer.appscode.com/issue-license >${tokenPath}
              ${pkgs.jq}/bin/jq --arg val "$(cat ${tokenPath})" '.global.license = $val' ${values} > ${valuesPath}
            '';
          }
          {
            chart = {
              repository = "appscode";
              name = "stash";
              version = "v2021.10.11";
            };
            name = "stash";
            namespace = "kube-system";
            values = valuesPath;
          }
          {
            script = ''
              ${pkgs.kubectl}/bin/kubectl -n kube-system rollout status deployment stash-stash-community --timeout=5m
              sleep 30s
            '';
          }
        ];
      };
  };
}
