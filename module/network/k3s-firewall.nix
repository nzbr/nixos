{ config, pkgs, lib, ... }:
with builtins; with lib; {
  options.nzbr.network.k3s-firewall = with types; {
    enable = mkEnableOption "firewall rules for my k3s loadbalancers";
  };

  config =
    let
      cfg = config.nzbr.network.k3s-firewall;
    in
    mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [
        80
        443
        2222
      ];

      boot.kernel.sysctl = {
        "ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    };
}
