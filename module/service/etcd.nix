{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.etcd = with types; {
    enable = mkEnableOption "etcd";
    ips = mkOption {
      type = attrsOf str;
      default = {
        storm = "10.42.0.1";
        earthquake = "10.42.0.2";
        avalanche = "10.42.0.4";
      };
    };
  };

  config = mkIf config.nzbr.service.etcd.enable (
    let
      hostname = config.networking.hostName;
      ips = config.nzbr.service.etcd.ips;
      ip = lib.attrByPath [ hostname ] null ips;
    in
    {
      nixpkgs.overlays = [
        (self: super: {
          etcd = super.etcd_3_4;
        })
      ];

      services.etcd = {
        enable = true;
        name = hostname;
        initialAdvertisePeerUrls = [ "http://${ip}:2380" ];
        advertiseClientUrls = [ "http://${ip}:2379" ];
        listenPeerUrls = [ "http://127.0.0.1:2380" "http://${ip}:2380" ];
        listenClientUrls = [ "http://127.0.0.1:2379" "http://${ip}:2379" ];
        initialClusterState = "existing";
        initialCluster = lib.mapAttrsToList (name: value: "${name}=http://${value}:2380") ips;
      };

      systemd.services.etcd = {
        after = [ "wireguard-wg0" ]; # TODO: Wait for connection to at least one other node
        requires = [ "wireguard-wg0" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 5;
        };
        environment = {
          ETCD_AUTO_COMPACTION_MODE = "revision";
          ETCD_AUTO_COMPACTION_RETENTION = "1000";
        };
      };
    }
  );
}
