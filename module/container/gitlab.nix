{ config, lib, pkgs, modulesPath, inputs, ... }:
with builtins; with lib; {
  options.nzbr.container.gitlab = {
    enable = mkEnableOption "GitLab";
    dataPath = mkStrOpt "/var/lib/gitlab";
    dnsIP = mkStrOpt "10.13.0.10";
    shmSize = mkStrOpt "256M";
    logLevel = mkStrOpt "info"; # debug, info, warn, error, fatal
  };

  config =
    let
      cfg = config.nzbr.container.gitlab;
    in
    mkIf cfg.enable {
      virtualisation.oci-containers.containers.gitlab = {
        autoStart = true;
        image = "gitlab/gitlab-ce:latest";
        volumes = [
          "${cfg.dataPath}/config:/etc/gitlab"
          "${cfg.dataPath}/data:/var/opt/gitlab"
        ];
        ports = [
          "${config.nzbr.nodeIp}:20022:22"
          "${config.nzbr.nodeIp}:20055:5005"
          "${config.nzbr.nodeIp}:20080:80"
          "${config.nzbr.nodeIp}:20090:8099"
        ];
        environment = {
          "GITLAB_LOG_LEVEL" = cfg.logLevel;
        };
        extraOptions = [
          "--dns=${cfg.dnsIP}"
          "--shm-size=${cfg.shmSize}"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };
    };

}
