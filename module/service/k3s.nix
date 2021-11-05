{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.k3s = {
    enable = mkEnableOption "K3s";
    nodeIp = strOption;
    dbHost = mkStrOpt "storm.nzbr.github.beta.tailscale.net";
  };

  config =
  let
    cfg = config.nzbr.service.k3s;
  in
  mkIf cfg.enable {
    # Was needed for longhorn, which I don't use anymore
    # nzbr.service.openIscsi.enable = true;

    services.k3s = {
      enable = true;
      docker = true;
      role = "server";
    };

    systemd.services.k3s = {
      serviceConfig = {
        ExecStart = lib.mkForce (
          "${pkgs.busybox}/bin/sh -c '${pkgs.k3s}/bin/k3s server"
          + " --disable=traefik"
          + " --docker"
          + " --cluster-cidr=10.12.0.0/16"
          + " --service-cidr=10.13.0.0/13"
          + " --cluster-dns=10.13.0.10"
          + " --cluster-domain=kube"
          + " --node-ip=${cfg.nodeIp}"
          + " --node-external-ip=${cfg.nodeIp}"
          + " --flannel-backend=none"
          + " --datastore-endpoint=postgres://kubernetes:$(cat ${config.nzbr.assets."k3s-db.password"})@${cfg.dbHost}:5432/kubernetes?sslmode=disable"
          + " --disable-network-policy"
          + " --write-kubeconfig /run/kubeconfig"
          + " --snapshotter=native"
          + "'"
        );
      };
    };

    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ];

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    environment.variables = {
      KUBECONFIG = "/run/kubeconfig";
    };

    networking.firewall.trustedInterfaces = [ "tunl0" ];

    # Needed for Rook-CEPH
    boot.kernelModules = [ "rbd" ];
  };
}
