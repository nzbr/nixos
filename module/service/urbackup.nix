{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.service.urbackup = with types; {
    enable = mkEnableOption "UrBackup Client Server backup system";
    package = mkOption {
      type = package;
      default = pkgs.local.urbackup2-server;
    };
    config = mkOption {
      type = attrsOf (oneOf [ str int bool ]);
    };
    backupfolder = mkOption {
      type = str;
      default = "/mnt/BACKUP/urbackup";
    };
    dataset = {
      images = mkOption {
        type = nullOr str;
        default = null;
      };
      files = mkOption {
        type = nullOr str;
        default = null;
      };
    };
  };

  config =
    let
      cfg = config.nzbr.service.urbackup;
    in
    mkIf cfg.enable {

      users = {
        users.urbackup = {
          isSystemUser = true;
          group = "urbackup";
        };
        groups.urbackup = { };
      };

      environment.systemPackages = with pkgs; [
        cfg.package
        libguestfs
      ];

      security.wrappers =
        let
          owner = "root";
          group = "root";
          setuid = true;
          permissions = "u+rx,g+rx,o+rx";
        in
        {
          urbackup_snapshot_helper = {
            source = "${cfg.package}/bin/urbackup_snapshot_helper";
            inherit owner group setuid permissions;
          };
          urbackup_mount_helper = {
            source = "${cfg.package}/bin/urbackup_mount_helper";
            inherit owner group setuid permissions;
          };
        };

      systemd.tmpfiles.rules = [
        "d /var/urbackup 0755 urbackup urbackup -"
      ];

      fileSystems."/usr/share/urbackup" = {
        device = "${cfg.package}/share/urbackup";
        fsType = "none";
        options = [ "bind" ];
      };

      environment.etc = {
        "urbackup/backupfolder".text = cfg.backupfolder;
        "urbackup/dataset".text = mkIf (cfg.dataset.images != null) cfg.dataset.images;
        "urbackup/dataset_file".text = mkIf (cfg.dataset.files != null) cfg.dataset.files;
      };

      systemd.services.urbackup-server =
        let
          configFile = pkgs.writeText "urbackup.conf" (
            generators.toKeyValue { } (mapAttrs
              (n: v: if isString v then "\"${v}\"" else (toString v))
              cfg.config
            )
          );
        in
        {
          description = "UrBackup Client/Server Network Backup System";

          wantedBy = [ "multi-user.target" ];
          after = [ "syslog.target" "network.target" ];

          path = [
            "/run/wrappers/bin"
            cfg.package
            pkgs.coreutils
            pkgs.curl
            pkgs.fuse
          ];

          serviceConfig = {
            ExecStart = "${cfg.package}/bin/urbackupsrv run --config ${configFile} --no-consoletime";
            User = "root";
            TasksMax = "infinity";
          };

        };

      nzbr.service.urbackup.config =
        mapAttrs
          (n: v: mkDefault v)
          {
            FASTCGI_PORT = 55413;
            HTTP_SERVER = "true"; # Needs to be a string for some reason
            HTTP_PORT = 55414;
            HTTP_LOCALHOST_ONLY = false;
            INTERNET_LOCALHOST_ONLY = false;
            LOGFILE = "/var/log/urbackup.log";
            LOGLEVEL = "warn";
            DAEMON_TMPDIR = "/tmp";
            SQLITE_TMPDIR = "";
            BROADCAST_INTERFACES = "";
            USER = "root";
          };

      networking.firewall.allowedTCPPorts = [ 55414 ];
      networking.firewall.allowedUDPPorts = [ 35623 ];

    };

}
