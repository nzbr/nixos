{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    # ./etcd.nix
    ./open-iscsi.nix
  ];

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
        + " --node-ip=${config.nzbr.wgIp}"
        + " --node-external-ip=${config.nzbr.wgIp}"
        + " --flannel-backend=none"
        # + " --datastore-endpoint=http://127.0.0.1:2379"
        + " --datastore-endpoint=postgres://kubernetes:$(cat ${config.nzbr.assets."k3s-db.password"})@10.42.0.1:5432/kubernetes?sslmode=disable"
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

  environment.etc."shell-hooks/99-kubeconfig.sh" = {
    mode = "0755";
    text = ''
      export KUBECONFIG=/run/kubeconfig
    '';
  };

  networking.firewall.trustedInterfaces = [ "tunl0" ];
}
