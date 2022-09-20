{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "cert-manager";
in
{
  nirgenx.deployment.cert-manager = {
    steps = [
      (kube.installHelmChart "jetstack" namespace { installCRDs = true; })
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = namespace;
          labels = {
            "certmanager.k8s.io/disable-validation" = "true";
          };
        };
      }
      {
        script =
          let
            repo = "${inputs.cert-manager-desec}";
            chart = pkgs.runCommand "cert-manager-desec" { } ''
              mkdir -p "$out"
              cp -r ${repo}/deploy/desec-webhook/. "$out";
              chmod -R u+rw "$out"
              find "$out" -type f -exec sed -i 's|cert-manager\.io/v1alpha3|cert-manager\.io/v1|' {} \;
            '';
            values = { };
          in
          "${pkgs.kubernetes-helm}/bin/helm upgrade -i -n '${namespace}' --create-namespace -f '${pkgs.writeText "values.yaml" (toJSON values)}' 'cert-manager-desec' '${chart}'";
      }
      (config.nzbr.assets."k8s/cert-manager-letsencrypt-config.yaml")
    ];
  };
}
