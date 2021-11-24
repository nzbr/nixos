{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.deployment.gitlab = {
    dependencies = [ "cert-manager" "keycloak" "nginx" "stash" ]; # TODO: kadalu
    steps = [

      (kube.createNamespace "gitlab-system")

      (
        pkgs.writeText "gitlab-operator-patched.yaml" (
          replaceStrings
          [ "cert-manager.io/v1alpha2" ]
          [ "cert-manager.io/v1" ]
          (
            readFile
            (
              fetchurl (
              let
                GL_OPERATOR_VERSION = "0.2.0";
                PLATFORM = "kubernetes";
              in
              {
                url = "https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${PLATFORM}-${GL_OPERATOR_VERSION}.yaml";
                sha256 = "ab0a281e1bb054a52179b66ee9d12c960ed3fe9bde9c68af1432fe0b1425b369";
              })
            )
          )
        )
      )

      {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata = {
          name = "gitlab-wildcard-tls";
          namespace = "gitlab-system";
        };
        spec = {
          dnsNames = [ "*.nzbr.de" "*.pages.nzbr.de" ];
          issuerRef = {
            group = "cert-manager.io";
            kind = "ClusterIssuer";
            name = "letsencrypt-prod";
          };
          secretName = "git.nzbr.de-wildcard-tls";
        };
      }

      (config.nzbr.assets."k8s/gitlab-secrets.yaml")

      {
        script = "kubectl create -n gitlab-system secret generic gitlab-rails-storage --from-file=connection=${config.nzbr.assets."k8s/gitlab-rails-storage.yaml"} --dry-run=client -o yaml | kubectl apply -f -";
      }

      {
        # Wait for operator to come online
        script = "kubectl -n gitlab-system rollout status deployment gitlab-controller-manager --timeout=5m";
      }

      {
        apiVersion = "apps.gitlab.com/v1beta1";
        kind = "GitLab";
        metadata = {
          name = "gitlab";
          namespace = "gitlab-system";
        };
        spec.chart = {
          version = "5.5.0";
          values =
          let
            tlsSecretName = "gitlab-wildcard-tls";
            storageClass = "kadalu.pool";
            storageSecret = "gitlab-rails-storage";
          in
          {
            certmanager.install = false;
            gitlab = {
              gitlab-pages.ingress.tls.secretName = tlsSecretName;
              gitlab-shell.service.type = "LoadBalancer";
              toolbox.persistence.storageClass = storageClass;
              webservice = {
                ingress = {
                  annotations = {
                    "nginx.ingress.kubernetes.io/proxy-body-size" = "20G";
                  };
                  tls.secretName = tlsSecretName;
                };
              };
            };
            gitlab-runner.install = false;
            global = {
              # appConfig = {
              #   ldap = {
              #     preventSignin = false;
              #     servers = {
              #       main = {
              #         active_directory = false;
              #         allow_username_or_email_login = true;
              #         attributes = {
              #           email = [ "mail" ];
              #           first_name = "givenName";
              #           last_name = "sn";
              #           name = [ "cn" ];
              #           username = [ "uid" ];
              #         };
              #         base = "ou=users,dc=nzbr,dc=de";
              #         bind_dn = "cn=admin,dc=nzbr,dc=de";
              #         block_auto_created_users = false;
              #         encryption = "plain";
              #         host = "openldap.ldap.svc.kube";
              #         label = "nzbr.de Account";
              #         lowercase_usernames = true;
              #         password = {
              #           key = "password";
              #           secret = "ldap-main-password";
              #         };
              #         port = 389;
              #         smartcard_auth = false;
              #         uid = "uid";
              #         user_filter =
              #           "(&(objectclass=inetOrgPerson)(memberof=cn=gitlab,ou=groups,dc=nzbr,dc=de))";
              #         verify_certificates = true;
              #       };
              #     };
              #   };
              # };
              appConfig = (
                listToAttrs
                (map
                  (svc:
                    nameValuePair
                      svc
                      {
                        bucket = "nzbr-gitlab-${svc}";
                        connection.secret = storageSecret;
                      }
                  )
                  [
                    "artifacts"
                    "lfs"
                    "packages"
                    "pseudonymizer"
                    "terraformState"
                    "uploads"
                  ]
                )
              );
              edition = "ce";
              gitaly = {
                authToken = {
                  key = "token";
                  secret = "gitlab-gitaly-secret";
                };
                enabled = false;
                external = [{
                  hostname = "gitlab-gitaly.gitlab.svc.kube";
                  name = "default";
                }];
              };
              hosts = {
                domain = "nzbr.de";
                gitlab.name = "git.nzbr.de";
                # minio = { name = "s3.nzbr.de"; };
                pages.name = "pages.nzbr.de";
                registry.name = "repo.nzbr.de";
              };
              ingress = {
                annotations = { "nginx.ingress.kubernetes.io/proxy-body-size" = "20G"; };
                class = "nginx";
                configureCertmanager = false;
              };
              minio.enabled = false;
              object_store = {
                enabled = true;
              };
              pages = {
                enabled = true;
                objectStore.bucket = "nzbr-gitlab-pages";
              };
              psql = {
                database = "gitlab";
                host = "storm.nzbr.github.beta.tailscale.net";
                password = {
                  key = "postgresql-password";
                  secret = "gitlab-postgresql-password";
                };
                username = "gitlab";
              };
              redis = {
                host = "redis-headless.redis.svc.kube";
                password = {
                  key = "password";
                  secret = "redis-password";
                };
              };
              registry.bucket = "nzbr-gitlab-registry";
              shell.port = 2222;
              inherit storageClass;
            };
            # minio = {
            #   ingress = {
            #     annotations = { "nginx.ingress.kubernetes.io/proxy-body-size" = "20G"; };
            #     tls = { secretName = "git.nzbr.de-wildcard-tls"; };
            #   };
            #   nodeSelector = { "kubernetes.io/hostname" = "avalanche"; };
            #   persistence = { storageClass = "local-path"; };
            # };
            nginx-ingress.enabled = false;
            postgresql.install = false;
            prometheus.install = false;
            redis.install = false;
            registry = {
              ingress = {
                annotations = {
                  "nginx.ingress.kubernetes.io/proxy-body-size" = "20G";
                  "nginx.ingress.kubernetes.io/proxy-read-timeout" = 900;
                };
                tls.secretName = tlsSecretName;
              };
              storage.secret = storageSecret;
            };
          };
        };
      }

      # TODO: gitaly

      # TODO: stash

    ];
  };
}
