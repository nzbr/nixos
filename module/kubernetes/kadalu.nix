{ config, lib, pkgs, inputs, ... }:
with builtins; with lib;
{
  kubenix.deployment.kadalu = {
    dependencies = [ ];
    steps = [
      {
        script = ''
          ${pkgs.local.kubectl-kadalu}/bin/kubectl-kadalu install --script-mode
          ${pkgs.local.kubectl-kadalu}/bin/kubectl-kadalu storage-add pool --script-mode --type=Replica3 --device storm:/dev/zvol/zroot/kadalu --device avalanche:/dev/zvol/zroot/kadalu --device earthquake:/dev/zvol/hoard/kadalu
        '';
      }
    ];
  };
}
