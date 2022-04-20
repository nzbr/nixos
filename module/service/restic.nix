{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.restic = with types; {
    enable = mkEnableOption "Restic Backups";
    remote = mkOption {
      type = str;
    };
    include = mkOption {
      type = listOf str;
    };
    healthcheck = {
      backup = mkOption {
        type = str;
      };
      prune = mkOption {
        type = str;
      };
    };
    snapshotName = mkOption {
      default = "backup";
      type = str;
    };
    keep = {
      last = mkOption {
        default = 3;
        type = int;
      };
      daily = mkOption {
        default = 7;
        type = int;
      };
      weekly = mkOption {
        default = 4;
        type = int;
      };
      monthly = mkOption {
        default = 12;
        type = int;
      };
    };
    pools = mkOption {
      default = [ ];
      type = listOf (submodule {
        options = {
          name = mkOption {
            type = str;
          };
          subvols = mkOption {
            default = [ ];
            type = listOf (submodule {
              options = {
                name = mkOption {
                  type = str;
                };
                mountpoint = mkOption {
                  type = str;
                };
              };
            });
          };
        };
      });
    };
  };

  config = mkIf config.nzbr.service.restic.enable (
    let
      hostname = config.networking.hostName;

      cfg = config.nzbr.service.restic;
      backupDir = "${cfg.remote}:restic/${hostname}";
    in
    {
      systemd = {
        services = {
          restic-backup = {
            path = with pkgs; [ curl rclone restic utillinux zfs ];
            environment = {
              HOME = "/root";
              RESTIC_PASSWORD_FILE = config.nzbr.assets."resticpass";
              RESTIC_REPOSITORY = "rclone:${backupDir}";
            };
            serviceConfig = {
              KillMode = "process";
            };
            preStart =
              lib.concatStringsSep "\n"
                (
                  [
                    "set -euxo pipefail"
                  ] ++ lib.flatten
                    (
                      builtins.map
                        (pool:
                          [
                            "zfs destroy -r ${pool.name}@${cfg.snapshotName} || true"
                            "zfs snapshot -r ${pool.name}@${cfg.snapshotName}"
                            "mkdir -p /tmp/.snapshot/${pool.name}"
                            "mount -t zfs ${pool.name}@${cfg.snapshotName} /tmp/.snapshot/${pool.name}"
                          ] ++ (
                            builtins.map
                              (subvol:
                                [
                                  "mount -t zfs ${pool.name}/${subvol.name}@${cfg.snapshotName} /tmp/.snapshot/${pool.name}/${subvol.mountpoint}"
                                ]
                              )
                              pool.subvols
                          )
                        )
                        cfg.pools
                    )
                );
            script = with builtins; ''
              set -euxo pipefail

              if ! rclone lsd ${backupDir}; then
                rclone mkdir ${backupDir}
                restic init
              fi

              while [ -f /tmp/restic.lock ]; do
                sleep 60s
              done
              touch /tmp/restic.lock

              cd /tmp/.snapshot
              restic backup --verbose=2 --exclude-caches ${lib.concatStringsSep " " (map (x: "./${x}") cfg.include)}
              restic unlock
              restic forget --group-by host --host ${hostname} --keep-last ${toString cfg.keep.last} --keep-daily ${toString cfg.keep.daily} --keep-weekly ${toString cfg.keep.weekly} --keep-monthly ${toString cfg.keep.monthly}
            ''
            + (
              if cfg.healthcheck.backup != "" then ''
                curl -s ${cfg.healthcheck.backup}
              ''
              else ""
            );
            postStop =
              lib.concatStringsSep "\n"
                (
                  [
                    "set -euxo pipefail"
                    "rm -f /tmp/restic.lock"
                  ] ++ lib.flatten
                    (
                      builtins.map
                        (pool:
                          (
                            builtins.map
                              (subvol:
                                [
                                  "umount /tmp/.snapshot/${pool.name}/${subvol.mountpoint}"
                                ]
                              )
                              (lib.reverseList pool.subvols)
                          ) ++ [
                            "umount /tmp/.snapshot/${pool.name}"
                            "rmdir /tmp/.snapshot/${pool.name}"
                            "zfs destroy -r ${pool.name}@${cfg.snapshotName}"
                          ]
                        )
                        (lib.reverseList cfg.pools)
                    )
                );
          };

          restic-prune = {
            path = with pkgs; [ curl rclone restic utillinux zfs ];
            environment = {
              HOME = "/root";
              RESTIC_PASSWORD_FILE = config.nzbr.assets."resticpass";
              RESTIC_REPOSITORY = "rclone:${backupDir}";
            };
            serviceConfig = {
              KillMode = "process";
            };
            script = ''
              set -euxo pipefail

              while [ -f /tmp/restic.lock ]; do
                sleep 60s
              done
              touch /tmp/restic.lock

              restic prune --verbose=2
            '' + (
              if cfg.healthcheck.prune != "" then ''
                curl -s ${cfg.healthcheck.prune}
              ''
              else ""
            );
            postStop = ''
              set -euxo pipefail
              rm -f /tmp/restic.lock
            '';
          };
        };

        timers = {
          restic-backup = {
            wantedBy = [ "timers.target" ];
            partOf = [ "restic-backup.service" ];
            timerConfig.OnCalendar = "*-*-* 05:00:00";
          };
          restic-prune = {
            wantedBy = [ "timers.target" ];
            partOf = [ "restic-prune.service" ];
            timerConfig.OnCalendar = "*-*-01 12:00:00";
          };
        };
      };
    }
  );
}
