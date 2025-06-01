{ config, pkgs, lib, inputs, ... }:
with builtins; with lib;
let
  namespace = "argocd";
in
{
  nirgenx.deployment.argocd = {
    steps = [

      (kube.createNamespace namespace)

      # (pkgs.runCommand "argocd.json"
      #   {
      #     nativeBuildInputs = [ pkgs.yq ];
      #   } ''
      #   yq -y '.metadata.namespace="${namespace}"' ${inputs.argocd}/manifests/install.yaml > $out
      # '')

      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRoleBinding";
        metadata = {
          name = "argocd";
          inherit namespace;
        };
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "cluster-admin";
        };
        subjects = [
          {
            inherit namespace;
            kind = "ServiceAccount";
            name = "argocd-application-controller";
          }
          {
            inherit namespace;
            kind = "ServiceAccount";
            name = "argocd-applicationset-controller";
          }
          {
            inherit namespace;
            kind = "ServiceAccount";
            name = "argocd-server";
          }
        ];
      }

      {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "AppProject";
        metadata = {
          inherit namespace;
          name = "default";
        };
        spec = {
          clusterResourceWhitelist = [
            { group = "*"; kind = "*"; }
          ];
          destinations = [
            { namespace = "*"; server = "*"; }
          ];
          sourceRepos = [
            "*"
          ];
        };
      }

      {
        apiVersion = "argoproj.io/v1alpha1";
        kind = "Application";
        metadata = {
          inherit namespace;
          name = "infrastructure";
          annotations = {
            "notifications.argoproj.io/subscribe.on-status-change.github" = "";
          };
        };
        spec = {
          project = "default";
          source = {
            repoURL = "https://github.com/nzbr/infrastructure.git";
            path = "kubernetes";
            targetRevision = "main";
          };
          destination = {
            namespace = "default";
            server = "https://kubernetes.default.svc";
          };
          syncPolicy.automated = {
            prune = true;
            selfHeal = true;
          };
        };
      }

      {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          inherit namespace;
          name = "argocd";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS";
          };
        };
        spec = {
          rules = [
            {
              host = "argocd.nzbr.de";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "argocd-server";
                        port = {
                          number = 443;
                        };
                      };
                    };
                  }
                ];
              };
            }
          ];
        };
      }

    ];
  };
}
