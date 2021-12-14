{ config, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.service.ceph = with types; {
    enable = mkEnableOption "CEPH";
  };

  config =
    let
      cfg = config.nzbr.service.ceph;
      hosts = inputs.self.packages.${system}.nixosConfigurations;
      cephHosts = filter (host: hosts.${host}.config.nzbr.service.ceph.enable) (attrNames hosts);
    in
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        ceph
      ];

      services.ceph = {
        enable = true;
        global = rec {
          fsid = "891e5ca6-c0e0-4d7f-9e38-28d7c7a5fa39";
          publicNetwork = "100.64.0.0/10";
          clusterNetwork = publicNetwork;
          monInitialMembers = concatStringsSep "," (map (host: hosts.${host}.config.networking.hostName) cephHosts);
          monHost = concatStringsSep "," (map (host: hosts.${host}.config.nzbr.nodeIp) cephHosts);
        };
        extraConfig = {
          "osd journal size" = "1024";
          "osd pool default size" = "3";
          "osd pool default min size" = "2";
          "osd pool default pg num" = "333";
          "osd pool default pgp num" = "333";
          "osd crush chooseleaf type" = "1";
        };
        mon = {
          enable = true;
          daemons = [ config.networking.hostName ];
          extraConfig = {
            "auth_allow_insecure_global_id_reclaim" = "false";
            "mgr_initial_modules" = "dashboard balancer";
          };
        };
        mgr = {
          enable = true;
          daemons = [ config.networking.hostName ];
        };
        mds = {
          enable = true;
          daemons = [ config.networking.hostName ];
        };
        osd = {
          enable = true;
          daemons = mkDefault [ ];
        };
      };

      system.activationScripts.ceph = stringAfter [ "agenix" "etc" ] ''
        echo setting up ceph
        mkdir -p /run/ceph /var/lib/ceph

        # copy secrets
        cp ${config.nzbr.assets."ceph/ceph.mon.keyring"} /run/ceph/ceph.mon.keyring
        cp ${config.nzbr.assets."ceph/ceph.client.admin.keyring"} /etc/ceph/ceph.client.admin.keyring
        cp ${config.nzbr.assets."ceph/bootstrap-osd.keyring"} /etc/ceph/ceph.client.bootstrap-osd.keyring

        # import keys to mon keyring
        ${pkgs.ceph}/bin/ceph-authtool /run/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
        ${pkgs.ceph}/bin/ceph-authtool /run/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.bootstrap-osd.keyring

        # build the monmap
        ${pkgs.ceph}/bin/monmaptool --create --clobber --fsid ${config.services.ceph.global.fsid} /run/ceph/monmap
        ${concatStringsSep "&&" (map (host: "${pkgs.ceph}/bin/monmaptool --add ${hosts.${host}.config.networking.hostName} ${hosts.${host}.config.nzbr.nodeIp} /run/ceph/monmap") cephHosts)}

        # initialize mon
        if ! [ -d "/var/lib/ceph/mon/ceph-${config.networking.hostName}/store.db" ]; then
          mkdir -p "/var/lib/ceph/mon/ceph-${config.networking.hostName}"
          ${pkgs.sudo}/bin/sudo -u ceph ${pkgs.ceph}/bin/ceph-mon --mkfs -i "${config.networking.hostName}" --monmap /run/ceph/monmap --keyring /run/ceph/ceph.mon.keyring
        fi

        chown -R ceph:ceph /run/ceph /etc/ceph /var/lib/ceph
      '';

      systemd.services."ceph-mgr-${config.networking.hostName}" = {
        after = [ "ceph-mon.target" ];
        unitConfig = {
          ConditionPathExists = mkForce null;
        };
        preStart = ''
          mkdir -p "/var/lib/ceph/mgr/ceph-${config.networking.hostName}"
          ${pkgs.ceph}/bin/ceph auth get-or-create mgr.${config.networking.hostName} mon 'allow profile mgr' osd 'allow *' mds 'allow *' > "/var/lib/ceph/mgr/ceph-${config.networking.hostName}/keyring"
          chown -R ceph:ceph "/var/lib/ceph/mgr/ceph-${config.networking.hostName}"
        '';
      };
    };
}
