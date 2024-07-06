{ config, lib, pkgs, modulesPath, inputs, ... }:
with builtins; with lib; {
  options.services.k3s = {
    dbHost = mkStrOpt "127.0.0.1";
    dbEndpoint = mkStrOpt "";
    dns = mkStrOpt "100.100.100.100";
  };

  config =
    let
      cfg = config.services.k3s;
      isServer = cfg.role == "server";
      resolvconf = pkgs.writeText "resolv.conf" ''
        nameserver ${cfg.dns}
      '';
      kubeconfigPath = "/run/kubeconfig";
    in
    mkIf cfg.enable {

      services.k3s = {
        serverAddr = mkDefault inputs.self.nixosConfigurations.firestorm.config.nzbr.nodeIp;
        tokenFile = mkDefault config.nzbr.assets."k3s-token";
        package = mkDefault pkgs.unstable.k3s;
      };

      systemd.services.k3s = {
        after = [
          "network.service"
          "firewall.service"
          "tailscaled.service"
        ];
        serviceConfig = {
          ExecStart = mkForce (
            let
              options = concatStringsSep " " ([
                "--node-ip=${config.nzbr.nodeIp},${config.nzbr.nodeIp6}"
                "--node-external-ip=${config.nzbr.nodeIp},${config.nzbr.nodeIp6}"
                "--flannel-iface=tailscale0"
                "--resolv-conf=${resolvconf}"
                # "--snapshotter=fuse-overlayfs"
                "--kubelet-arg=cgroup-driver=systemd"
                "--kubelet-arg=runtime-request-timeout=5m0s"
              ] ++ (if isServer then [
                "--cluster-init"
                "--datastore-endpoint=${cfg.dbEndpoint}"
                "--disable=traefik"
                "--cluster-cidr=10.12.0.0/16,2001:b0a7:12::/56"
                "--service-cidr=10.13.0.0/16,2001:b0a7:13::/112"
                "--cluster-dns=10.13.0.10"
                "--cluster-domain=kube"
                "--advertise-address=${config.nzbr.nodeIp}"
                "--flannel-backend=vxlan"
                "--flannel-ipv6-masq"
                "--disable-network-policy"
                "--write-kubeconfig ${kubeconfigPath}"
              ] else [
                " --server https://${cfg.serverAddr}:6443"
              ]));
            in
            "${pkgs.busybox}/bin/sh -c '"
            # + "export PATH=$PATH:${pkgs.fuse-overlayfs}/bin:${pkgs.fuse3}/bin && " # PATH is set with ENVIRONMENT= and not Path=, so it can't be easily overwritten, irrelevant for docker
            + "export K3S_TOKEN=$(cat ${cfg.tokenFile}) && "
            + "exec ${cfg.package}/bin/k3s ${cfg.role} ${options}"
            + "'"
          );
        };
      };

      systemd.services.tailscaled.serviceConfig.Environment = [ "TS_DEBUG_MTU=1420" ];

      environment.systemPackages = with pkgs; [
        cfg.package
        kubectl
        kubernetes-helm
        local.kubectl-kadalu
        local.kubectl-killnamespace
      ];

      environment.variables = {
        KUBECONFIG = mkIf isServer kubeconfigPath;
      };

      networking.firewall.trustedInterfaces = [ "tunl0" "flannel.1" "cni0" ];

    };
}
