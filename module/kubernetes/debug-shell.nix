{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
let
  pkgs = [ "base" "base-devel" "git" ];
in
{
  kubenix.deployment.debug-shell.steps = [
    {
      apiVersion = "apps/v1";
      kind = "DaemonSet";
      metadata = {
        labels = { k8s-app = "debug-shell"; };
        name = "debug-shell";
        namespace = "default";
      };
      spec = {
        selector = { matchLabels = { name = "debug-shell"; }; };
        template = {
          metadata = { labels = { name = "debug-shell"; }; };
          spec = {
            containers = [{
              name = "shell";
              image = "docker.io/library/archlinux";
              command = [ "bash" "-c" "pacman -Syu --noconfirm ${concatStringsSep " " pkgs} && exec sleep infinity" ];
            }];
            terminationGracePeriodSeconds = 30;
            tolerations = [{
              effect = "NoSchedule";
              key = "node-role.kubernetes.io/master";
            }];
          };
        };
      };
    }
  ];
}
