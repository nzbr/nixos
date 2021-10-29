{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.vaultwarden = {
    dependencies = [ "nginx" "rook-ceph" ];
    steps = [
      {
        chart = {
          repository = "k8s-at-home";
          name = "vaultwarden";
        };
        name = "vaultwarden";
        namespace = "vaultwarden";
        values = config.nzbr.assets."k8s/vaultwarden-values.yaml";
      }
    ];
  };
}
