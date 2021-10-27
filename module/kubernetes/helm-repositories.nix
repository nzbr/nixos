{ config, lib, pkgs, ... }:
with builtins; with lib; {
  config =
    let
      cfg = config.kubenix;
    in
    mkIf cfg.enable {
      systemd.services = {
        helm-repositories = rec {
          requires = cfg.waitForUnits;
          after = requires;
          wantedBy = [ "multi-user.target" ];
          environment = {
            HOME = config.users.users.root.home;
            KUBECONFIG = cfg.kubeconfigPath;
          };
          serviceConfig = {
            Type = "oneshot";
          };
          script =
            concatStringsSep "\n" (
              (
                mapAttrsToList
                  (name: url: "${cfg.helmPackage}/bin/helm repo add --force-update \"${name}\" \"${url}\"")
                  cfg.helmRepository
              ) ++ [ "${cfg.helmPackage}/bin/helm repo update" ]
            );
        };
      };
    };
}
