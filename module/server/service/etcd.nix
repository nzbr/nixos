{ config, lib, pkgs, modulesPath, ... }:
let
  hostname = config.networking.hostName;
  ips = {
    storm = "10.42.0.1";
    earthquake = "10.42.0.2";
    # avalanche = "10.42.0.4";
  };
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
    after = [ "wireguard-wg0" ];
    requires = [ "wireguard-wg0" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
