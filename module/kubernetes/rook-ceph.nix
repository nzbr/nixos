{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  kubenix.deployment.rook-ceph.steps = [
    "${inputs.rook}/cluster/examples/kubernetes/ceph/crds.yaml"
    "${inputs.rook}/cluster/examples/kubernetes/ceph/common.yaml"
    "${inputs.rook}/cluster/examples/kubernetes/ceph/operator.yaml"
    {
      apiVersion = "ceph.rook.io/v1";
      kind = "CephCluster";
      metadata = {
        name = "rook-ceph";
        namespace = "rook-ceph";
      };
      spec = {
        annotations = null;
        cephVersion = {
          allowUnsupported = false;
          image = "ceph/ceph:v15.2.13";
        };
        cleanupPolicy = {
          allowUninstallWithVolumes = false;
          confirmation = "";
          sanitizeDisks = {
            dataSource = "zero";
            iteration = 1;
            method = "quick";
          };
        };
        continueUpgradeAfterChecksEvenIfNotHealthy = false;
        crashCollector = { disable = false; };
        dashboard = {
          enabled = true;
          ssl = false;
        };
        dataDirHostPath = "/var/lib/rook";
        disruptionManagement = {
          machineDisruptionBudgetNamespace = "openshift-machine-api";
          manageMachineDisruptionBudgets = false;
          managePodBudgets = true;
          osdMaintenanceTimeout = 30;
          pgHealthCheckTimeout = 0;
        };
        healthCheck = {
          daemonHealth = {
            mon = {
              disabled = false;
              interval = "45s";
            };
            osd = {
              disabled = false;
              interval = "60s";
            };
            status = {
              disabled = false;
              interval = "60s";
            };
          };
          livenessProbe = {
            mgr = { disabled = false; };
            mon = { disabled = false; };
            osd = { disabled = false; };
          };
        };
        labels = null;
        mgr = {
          count = 1;
          modules = [{
            enabled = true;
            name = "pg_autoscaler";
          }];
        };
        mon = {
          allowMultiplePerNode = false;
          count = 3;
        };
        monitoring = {
          enabled = false;
          rulesNamespace = "rook-ceph";
        };
        network = null;
        removeOSDsIfOutAndSafeToRemove = false;
        resources = null;
        skipUpgradeChecks = false;
        storage = {
          config = null;
          devicePathFilter = "/dev/zvol/.*/rook";
          onlyApplyOSDPlacement = false;
          useAllDevices = false;
          useAllNodes = true;
        };
        waitTimeoutForHealthyOSDInMinutes = 10;
      };
    }
  ];
}
