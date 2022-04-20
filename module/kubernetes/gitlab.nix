{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  namespace = "gitlab";
  tlsHosts = [ "*.nzbr.de" "*.pages.nzbr.de" ];
  tlsSecretName = "gitlab-wildcard-cert";
in
{
  nirgenx.deployment.gitlab =
    {
      dependencies = [ "cert-manager" "nginx" ];
      steps = [

        (kube.createNamespace namespace)

        {
          apiVersion = "cert-manager.io/v1";
          kind = "Certificate";
          metadata = {
            name = "gitlab-wildcard-tls";
            inherit namespace;
          };
          spec = {
            dnsNames = tlsHosts;
            issuerRef = {
              group = "cert-manager.io";
              kind = "ClusterIssuer";
              name = "letsencrypt-prod";
            };
            secretName = tlsSecretName;
          };
        }

        {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            name = "gitlab";
          };
          spec = {
            type = "ClusterIP";
            ports = [
              {
                protocol = "TCP";
                name = "ssh";
                port = 20022;
              }
              {
                protocol = "TCP";
                name = "registry";
                port = 20055;
              }
              {
                protocol = "TCP";
                name = "www";
                port = 20080;
              }
            ];
          };
        }
        {
          apiVersion = "v1";
          kind = "Endpoints";
          metadata = {
            inherit namespace;
            name = "gitlab";
          };
          subsets = [{
            addresses = [{
              ip = inputs.self.nixosConfigurations.earthquake.config.nzbr.nodeIp;
            }];
            ports = [
              {
                name = "www";
                port = 20080;
              }
              {
                name = "registry";
                port = 20055;
              }
              {
                name = "ssh";
                port = 20022;
              }
            ];
          }];
        }

        {
          apiVersion = "networking.k8s.io/v1";
          kind = "Ingress";
          metadata = {
            inherit namespace;
            name = "gitlab-web";
            annotations = {
              "kubernetes.io/ingress.class" = "nginx";
              "nginx.ingress.kubernetes.io/proxy-body-size" = "20G";
              "nginx.ingress.kubernetes.io/proxy-read-timeout" = "900";
            };
          };
          spec = {
            rules = [
              {
                host = "git.nzbr.de";
                http = {
                  paths = [{
                    backend.service = {
                      name = "gitlab";
                      port.name = "www";
                    };
                    path = "/";
                    pathType = "Prefix";
                  }];
                };
              }
              {
                host = "registry.nzbr.de";
                http = {
                  paths = [{
                    backend.service = {
                      name = "gitlab";
                      port.name = "registry";
                    };
                    path = "/";
                    pathType = "Prefix";
                  }];
                };
              }
            ];
            tls = [{
              hosts = tlsHosts;
              secretName = tlsSecretName;
            }];
          };
        }

        # (config.nzbr.assets."k8s/gitlab-agent.yaml")

      ];
    };

  nzbr.nginx.tcp-services = mkIf config.nirgenx.deployment.gitlab.enable {
    "2222" = "${namespace}/gitlab:20022";
  };
}
