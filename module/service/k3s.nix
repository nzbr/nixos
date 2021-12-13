{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.k3s = {
    enable = mkEnableOption "K3s";
    dbHost = mkStrOpt "storm.nzbr.github.beta.tailscale.net";
    dns = mkStrOpt "100.100.100.100";
  };

  config =
    let
      cfg = config.nzbr.service.k3s;
      resolvconf = pkgs.writeText "resolv.conf" ''
        nameserver ${cfg.dns}
      '';
    in
    mkIf cfg.enable {

      services.k3s = {
        enable = true;
        docker = true;
        role = "server";
      };

      systemd.services.k3s = {
        serviceConfig = {
          after = [
            "network.service"
            "firewall.service"
            "docker.service"
            "tailscaled.service"
          ];
          ExecStart = lib.mkForce (
            "${pkgs.busybox}/bin/sh -c '"
            + "export PATH=$PATH:${pkgs.fuse-overlayfs}/bin:${pkgs.fuse3}/bin" # PATH is set with ENVIRONMENT= and not Path=, so it can't be easily overwritten, irrelevant for docker
            + "&& ${pkgs.k3s}/bin/k3s server"
            + " --disable=traefik"
            + " --docker"
            + " --cluster-cidr=10.12.0.0/16"
            + " --service-cidr=10.13.0.0/16"
            + " --cluster-dns=10.13.0.10"
            + " --cluster-domain=kube"
            + " --advertise-address=${config.nzbr.nodeIp}"
            + " --node-ip=${config.nzbr.nodeIp}"
            + " --node-external-ip=${config.nzbr.nodeIp}"
            + " --flannel-iface=tailscale0"
            + " --flannel-backend=vxlan"
            + " --resolv-conf=${resolvconf}"
            + " --datastore-endpoint=postgres://kubernetes:$(cat ${config.nzbr.assets."k3s-db.password"})@${cfg.dbHost}:5432/kubernetes?sslmode=disable"
            + " --disable-network-policy"
            + " --write-kubeconfig /run/kubeconfig"
            + " --snapshotter=fuse-overlayfs" # irrelevant for docker
            + "'"
          );
        };
      };

      environment.systemPackages = with pkgs; [
        k3s
        kubectl
        kubernetes-helm
        local.kubectl-kadalu
        local.kubectl-killnamespace
      ];

      environment.variables = {
        KUBECONFIG = "/run/kubeconfig";
      };

      networking.firewall.trustedInterfaces = [ "tunl0" "flannel.1" "cni0" ];

      boot.kernelModules = [
        "rbd" # CEPH (RADOS block device)
      ];

      virtualisation.docker.autoPrune.enable = true;
    };
}
