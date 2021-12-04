{ config, lib, pkgs, modulesPath, inputs, ... }:
with builtins; with lib; {
  options.nzbr.container.gitaly = {
    enable = mkEnableOption "Gitaly";
    storageName = mkStrOpt "default";
    dataPath = mkStrOpt "/storage/gitaly";
    dnsIp = mkStrOpt "10.13.0.10";
    workhorseUrl = mkStrOpt "http://gitlab-webservice-default.gitlab.svc.kube:8181/";
    gitalySecretFile = strOption;
    gitlabShellSecretFile = strOption;
  };

  config =
    let
      cfg = config.nzbr.container.gitaly;
    in
    mkIf cfg.enable {
      virtualisation.oci-containers.containers.gitaly =
        let
          configDrv = pkgs.writeText "config.toml.erb" ''
            # The directory where Gitaly's executables are stored
            bin_dir = "/usr/local/bin"

            # listen on a TCP socket. This is insecure (no authentication)
            listen_addr = "0.0.0.0:8075"

            # Directory where internal sockets reside
            internal_socket_dir = "/home/git"

            # If metrics collection is enabled, inform gitaly about that
            prometheus_listen_addr = "0.0.0.0:9236"

            [[storage]]
            name = "${cfg.storageName}"
            path = "/home/git/repositories"

            [logging]
            format = "json"
            dir = "/var/log/gitaly"

            [auth]
            token = "<%= File.read('/etc/gitlab-secrets/gitaly/gitaly_token').strip.dump[1..-2] %>"

            [git]

            [gitaly-ruby]
            # The directory where gitaly-ruby is installed
            dir = "/srv/gitaly-ruby"
            rugged_git_config_search_path = "/usr/local/etc"

            [gitlab-shell]
            # The directory where gitlab-shell is installed
            dir = "/srv/gitlab-shell"

            [gitlab]
            # location of shared secret for GitLab Shell / API interaction
            secret_file = "/etc/gitlab-secrets/shell/.gitlab_shell_secret"
            # URL of API
            url = "${cfg.workhorseUrl}"

            [gitlab.http-settings]
            # read_timeout = 300
            # user = someone
            # password = somepass
            # ca_file = /etc/ssl/cert.pem
            # ca_path = /etc/pki/tls/certs
            self_signed_cert = false

            [hooks]
            # directory containing custom hooks
            custom_hooks_dir = "/home/git/custom_hooks"
          '';
        in
        {
          autoStart = true;
          # image = "registry.gitlab.com/gitlab-org/build/cng/gitaly:latest";
          image = "registry.gitlab.com/gitlab-org/build/cng/gitaly:v14.5.2";
          volumes = [
            "${configDrv}:/etc/gitaly/templates/config.toml.erb:ro"
            "${cfg.gitalySecretFile}:/etc/gitlab-secrets/gitaly/gitaly_token:ro"
            "${cfg.gitlabShellSecretFile}:/etc/gitlab-secrets/shell/.gitlab_shell_secret:ro"
            "${cfg.dataPath}:/home/git/repositories"
            "${inputs.self}/asset/k8s/gitlab/certs:/etc/ssl/certs"
          ];
          environment = {
            CONFIG_TEMPLATE_DIRECTORY = "/etc/gitaly/templates";
            CONFIG_DIRECTORY = "/etc/gitaly";
            GITALY_CONFIG_FILE = "/etc/gitaly/config.toml";
            SSL_CERT_DIR = "/etc/ssl/certs";
          };
          extraOptions = [
            "--dns=${cfg.dnsIp}"
            "--network=host"
            "--label=com.centurylinklabs.watchtower.enable=true"
          ];
        };
    };
}
