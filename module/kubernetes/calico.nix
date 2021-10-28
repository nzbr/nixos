{ config, lib, pkgs, ... }:
with builtins; with lib; {
  kubenix.deployment.calico = {
    steps = [
      "https://docs.projectcalico.org/manifests/tigera-operator.yaml"
      {
        apiVersion = "operator.tigera.io/v1";
        kind = "Installation";
        metadata = {
          name = "default";
        };
        spec = {
          calicoNetwork = {
            containerIPForwarding = "Enabled";
            ipPools = [
              {
                blockSize = 26;
                cidr = "10.12.0.0/16";
                encapsulation = "IPIP";
                natOutgoing = "Enabled";
                nodeSelector = "all()";
              }
            ];
          };
        };
      }
    ];
  };
}
