{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.deployment.gitlab = {
    dependencies = [ "cert-manager" "keycloak" "nginx" "stash" ]; # TODO: kadalu
    steps = [

      (kube.createNamespace "gitlab")

      "https://gitlab.com/gitlab-org/charts/gitlab/raw/v3.0.0/support/crd.yaml" # install CRDs

      {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata = {
          name = "gitlab-wildcard-tls";
          namespace = "gitlab";
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

      (config.nzbr.assets."k8s/gitlab/gitlab-secrets.yaml")

      {
        script = ''
          kubectl create -n gitlab secret generic gitlab-rails-storage --from-file=connection=${config.nzbr.assets."k8s/gitlab/gitlab-rails-storage.yaml"} --from-file=config=${config.nzbr.assets."k8s/gitlab/gitlab-registry-storage.yaml"} --dry-run=client -o yaml | kubectl apply -f -
          kubectl create -n gitlab secret generic toolbox-storage --from-file=config=${config.nzbr.assets."k8s/gitlab/gitlab-toolbox-storage"} --dry-run=client -o yaml | kubectl apply -f -
        '';
      }

      (kube.installHelmChart "gitlab" "gitlab" (
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
            toolbox = {
              backups.objectStorage = {
                config = {
                  secret = "toolbox-storage";
                  key = "config";
                };
              };
              persistence.storageClass = storageClass;
            };
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
            ) // {
              backups = {
                bucket = "nzbr-gitlab-backups";
                tmpBucket = "nzbr-gitlab-backups-tmp";
              };
              ldap = {
                preventSignin = false;
                servers = {
                  main = {
                    active_directory = false;
                    allow_username_or_email_login = true;
                    attributes = {
                      email = [ "mail" ];
                      first_name = "givenName";
                      last_name = "sn";
                      name = [ "cn" ];
                      username = [ "uid" ];
                    };
                    base = "ou=users,dc=nzbr,dc=de";
                    bind_dn = "cn=admin,dc=nzbr,dc=de";
                    block_auto_created_users = false;
                    encryption = "plain";
                    host = "openldap.ldap.svc.kube";
                    label = "nzbr.de Account";
                    lowercase_usernames = true;
                    password = {
                      key = "password";
                      secret = "ldap-main-password";
                    };
                    port = 389;
                    smartcard_auth = false;
                    uid = "uid";
                    # user_filter = "(&(objectclass=inetOrgPerson)(memberof=cn=gitlab,ou=groups,dc=nzbr,dc=de))";
                    user_filter = "(objectclass=inetOrgPerson)";
                    verify_certificates = true;
                  };
                };
              };
              email = rec {
                display_name = "GitLab";
                from = "no-reply@nzbr.de";
                reply_to = from;
              };
              smtp = {
                enabled = true;
                address = "smtp.mailbox.org";
                tls = true;
                authentication = "plain";
                user_name = "mail" + "@" + "nzbr.de";
                password = {
                  secret = "smtp-password";
                  key = "password";
                };
              };
            };
            edition = "ce";
            gitaly = {
              authToken = {
                key = "token";
                secret = "gitlab-gitaly-secret";
              };
              enabled = false;
              external = [{
                hostname = "earthquake.nzbr.github.beta.tailscale.net";
                name = "default";
              }];
            };
            hosts = {
              domain = "nzbr.de";
              gitlab.name = "git.nzbr.de";
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
              host = "redis-master.redis.svc.kube";
              password = {
                key = "password";
                secret = "redis-password";
              };
            };
            registry.bucket = "nzbr-gitlab-registry";
            shell.port = 2222;
            inherit storageClass;
          };
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
        }
      ))

      # TODO: gitaly

      # TODO: stash

    ];
  };
}
