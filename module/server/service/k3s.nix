{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./etcd.nix
    ./open-iscsi.nix
  ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags =
      "--disable=traefik"
      + " --cluster-cidr=10.12.0.0/16"
      + " --service-cidr=10.13.0.0/13"
      + " --cluster-dns=10.13.0.10"
      + " --cluster-domain=kube"
      + " --node-ip=${config.nzbr.wgIp}"
      + " --node-external-ip=${config.nzbr.wgIp}"
      + " --flannel-backend=none"
      + " --datastore-endpoint=http://127.0.0.1:2379"
      + " --disable-network-policy"
    ;
  };

  environment.systemPackages = with pkgs; [
    k3s
    kubectl
    helm
  ];

  networking.firewall.trustedInterfaces = [ "tunl0" ];
}
