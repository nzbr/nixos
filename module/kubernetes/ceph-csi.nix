# based on https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/#configure-ceph-csi

{ config, lib, pkgs, system, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.ceph-csi =
  let
    hosts = inputs.self.packages.${system}.nixosConfigurations;
    cephHosts = filter (host: hosts.${host}.config.nzbr.service.ceph.enable) (attrNames hosts);
  in
  {
    steps = [
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata.name = "ceph-csi-config";
        data."config.json" = ''
          [
            {
              "clusterID": "${config.services.ceph.global.fsid}",
              "monitors": [
                ${ concatStringsSep ",\n" (map (host: "\"${hosts.${host}.config.nzbr.nodeIp}:6789\"") cephHosts)}
              ]
            }
          ]
        '';
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata.name = "ceph-csi-encryption-kms-config";
        data."config.json" = "{}";
      }
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata.name = "ceph-config";
        data = {
          "ceph.conf" = ''
            [global]
            auth_cluster_required = cephx
            auth_service_required = cephx
            auth_client_required = cephx
          '';
          keyring = "";
        };
      }
      "${inputs.ceph-csi}/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml"
      "${inputs.ceph-csi}/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml"
      "${inputs.ceph-csi}/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml"
      "${inputs.ceph-csi}/deploy/rbd/kubernetes/csi-rbdplugin.yaml"
      {
        allowVolumeExpansion = true;
        apiVersion = "storage.k8s.io/v1";
        kind = "StorageClass";
        metadata.name = "ceph";
        mountOptions = [ "discard" ];
        parameters = {
          clusterID = config.services.ceph.global.fsid;
          "csi.storage.k8s.io/controller-expand-secret-name" = "csi-rbd-secret";
          "csi.storage.k8s.io/controller-expand-secret-namespace" = "default";
          "csi.storage.k8s.io/node-stage-secret-name" = "csi-rbd-secret";
          "csi.storage.k8s.io/node-stage-secret-namespace" = "default";
          "csi.storage.k8s.io/provisioner-secret-name" = "csi-rbd-secret";
          "csi.storage.k8s.io/provisioner-secret-namespace" = "default";
          imageFeatures = "layering";
          pool = "k8s";
        };
        provisioner = "rbd.csi.ceph.com";
        reclaimPolicy = "Delete";
      }
    ];
  };

  systemd.services.kubernetes-ceph-secret = mkIf config.kubenix.deployment.ceph-csi.enable rec {
    inherit (config.systemd.services.kubernetes-deployment-ceph-csi) environment;
    wantedBy = [ "multi-user.target" ];
    requires = [ "kubernetes-deployment-ceph-csi.service" ];
    after = requires;
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.kubectl}/bin/kubectl \
        -n default \
        create secret generic \
        csi-rbd-secret \
        --type="kubernetes.io/rbd" \
        --from-literal=userID=kube \
        --from-literal=userKey="$(${pkgs.ceph}/bin/ceph auth get-key client.kube)" \
        --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
    '';
  };
}
