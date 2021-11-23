{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
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
        script = "sleep 30s";
      }
      config.nzbr.assets."k8s/stash-repo-wasabi.yaml"
    ];
  };
}
