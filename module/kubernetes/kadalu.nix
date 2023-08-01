{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  nirgenx.deployment.kadalu = {
    dependencies = [ ];
    steps = [

      {
        script = ''
          ${pkgs.local.kubectl-kadalu}/bin/kubectl-kadalu install --script-mode
        '';
      }

      {
        apiVersion = "kadalu-operator.storage/v1alpha1";
        kind = "KadaluStorage";
        metadata = {
          name = "pool";
        };
        spec = {
          type = "Replica1";
          storage = [
            {
              node = "firestorm";
              device = "/dev/zvol/zroot/kadalu";
            }
          ];
        };
      }

    ];
  };
}
