{ config, lib, pkgs, modulesPath, inputs, ... }:
with builtins; with lib; {
  options.nzbr.container.gitlab = {
    enable = mkEnableOption "GitLab";
    dataPath = mkStrOpt "/storage/gitlab";
    dnsIP = mkStrOpt "10.13.0.10";
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
          "${config.nzbr.nodeIp}:20080:80"
        ];
        extraOptions = [
          "--dns=${cfg.dnsIP}"
          "--label=com.centurylinklabs.watchtower.enable=true"
        ];
      };
    };

}
