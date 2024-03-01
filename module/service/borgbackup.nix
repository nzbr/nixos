{ config, lib, pkgs, options, ... }:
with builtins; with lib; {
  options.nzbr.service.borgbackup = with types; {
    enable = mkEnableOption "Borg Backups";
    rcloneRemote = mkOption {
      type = str;
    };
    repoUrl = mkOption {
      type = str;
    };
    paths = mkOption {
      type = listOf str;
      default = [ ];
    };
    zfs = {
      snapshotName = mkOption {
        type = str;
        default = "borgbackup";
        description = "Name of the ZFS snapshot to use for the backup";
      };
      pools = mkOption {
        default = [ ];
        type = listOf (submodule {
          options = {
            name = mkOption {
              type = str;
            };
            mountpoint = mkOption {
              type = nullOr str;
            };
            recursive = mkOption {
              default = false;
              type = bool;
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
    healthcheckUrl = mkOption {
      type = str;
    };
  };


  config = mkIf config.nzbr.service.borgbackup.enable (
    let
      cfg = config.nzbr.service.borgbackup;
      opt = options.nzbr.service.borgbackup;
      runDir = "/run/borg";
      cachePath = "${runDir}/rclone-cache";
      mountPath = "${runDir}/rclone-mount";
      repoPath = cfg.repoUrl or "${mountPath}/borg/${config.networking.hostName}";
      snapshotPath = "${runDir}/snapshot";
      specialFilesList = "${runDir}/special-files";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${cachePath} 0755 root root -"
      ];

      system.fsPackages = [
        (pkgs.runCommand "mount.rclone" { } ''
          mkdir -p $out/bin
          ln -s ${pkgs.rclone}/bin/rclone $out/bin/mount.rclone
        '')
      ];

      fileSystems.${mountPath} =
        assert (opt.rcloneRemote.isDefined) != (opt.repoUrl.isDefined);
        mkIf opt.rcloneRemote.isDefined {
          device = "${cfg.rcloneRemote}:";
          fsType = "rclone";
          options = [
            "user"
            "noauto"
            "_netdev"
            "rw"
            "allow_other"
            "args2env"
            "vfs-cache-mode=writes"
            "vfs-cache-max-size=1G"
            "config=/root/.config/rclone/rclone.conf"
            "cache-dir=${cachePath}"
            "log-file=${runDir}/rclone.log"
            "x-systemd.automount"
            "x-systemd.mount-timeout=5"
            "x-systemd.idle-timeout=30"
          ];
        };

      environment.systemPackages = with pkgs; [
        borgmatic
        borgbackup
        rclone
      ];

      environment.etc."borgmatic/config.yaml".text = generators.toJSON { } {

        exclude_caches = true;
        read_special = true;
        encryption_passcommand = "cat ${config.nzbr.assets."backup.password"}";
        compression = "auto,zstd,9";
        checkpoint_interval = 300;
        lock_wait = 300;

        repositories = [
          { label = "repository"; path = repoPath; }
        ];

        source_directories = flatten [
          cfg.paths
          snapshotPath
        ];

        exclude_from = [
          specialFilesList
        ];

        retention = {
          keep_daily = 7;
          keep_monthly = 12;
          keep_weekly = 4;
          keep_yearly = 5;
        };

        consistency = {
          check_last = 7;
          checks = [
            {
              name = "repository";
              frequency = "1 week";
            }
            {
              name = "archives";
              frequency = "1 week";
            }
            {
              name = "data";
              frequency = "1 month";
            }
            {
              name = "extract";
              frequency = "3 month";
            }
          ];
        };

        hooks = {
          before_backup = [
            (pkgs.writeShellScript "borg-pre-backup_snapshot" ''
              set -euxo pipefail

              umount -R ${snapshotPath} || true
              mount --mkdir -t tmpfs tmpfs ${snapshotPath}

              ${concatStringsSep "\n" (
                map
                (pool:
                  assert pool.recursive -> pool.subvols == [ ];
                  let
                    mountpoint =
                      if pool.mountpoint == null
                      then "${snapshotPath}/"
                      else "${snapshotPath}/${removePrefix "/" pool.mountpoint}";
                  in
                  ''
                    zfs destroy -r ${pool.name}@${cfg.zfs.snapshotName} || true
                    zfs snapshot -r ${pool.name}@${cfg.zfs.snapshotName}
                    mkdir -p ${mountpoint}
                    ${optionalString (pool.mountpoint != null) ''
                      mount -t zfs ${pool.name}@${cfg.zfs.snapshotName} ${mountpoint}
                    ''}
                    ${concatStringsSep "\n" (map
                      (subvol: "mount --mkdir -t zfs ${pool.name}/${subvol.name}@${cfg.zfs.snapshotName} ${mountpoint}/${removePrefix "/" subvol.mountpoint}")
                      pool.subvols
                    )}
                    ${optionalString pool.recursive ''
                      mountRoot="$(zfs list -Ho mountpoint ${pool.name})"
                      for subvol in $(zfs list -rHo name,mountpoint ${pool.name} | sed 's|${pool.name}/||' | awk 'NR!=1&&$2!="-"{print $1;}'); do
                        subMount="$(zfs list -Ho mountpoint ${pool.name}/''${subvol})"
                        if [[ "$subMount" != "none" && "$subMount" != "-" ]]; then
                          if [[ "$mountRoot" == "legacy" ]]; then
                            mount --mkdir -t zfs "${pool.name}/''${subvol}@${cfg.zfs.snapshotName}" "${mountpoint}/$subvol"
                          else
                            mount --mkdir -t zfs "${pool.name}/''${subvol}@${cfg.zfs.snapshotName}" "${mountpoint}''${subMount#$mountRoot}"
                          fi
                        fi
                      done
                    ''}
                  ''
                )
                cfg.zfs.pools
              )}
            '')
            (pkgs.writeShellScript "borg-pre-backup_find-special" ''
              set -euxo pipefail
              find ${snapshotPath} -xtype b,c,p,s -fprint ${specialFilesList}
              echo "Excluding $(wc -l ${specialFilesList} | ${pkgs.gawk}/bin/awk '{print $1;}') special files"
            '')
          ];
          after_backup = [
            (pkgs.writeShellScript "borg-post-backup" ''
              set -euxo pipefail
              umount -R ${snapshotPath}

              ${concatStringsSep "\n" (map
                (pool: "zfs destroy -r ${pool.name}@${cfg.zfs.snapshotName}")
                (reverseList cfg.zfs.pools)
              )}
            '')
          ];
          healthchecks.ping_url = cfg.healthcheckUrl;
        };
      };

      systemd = {
        services.borgmatic = {
          path = with pkgs; [ borgmatic "/run/wrappers" gawk zfs ];
          script = "borgmatic --files --stats";
        };

        timers.borgmatic = {
          wantedBy = [ "timers.target" ];
          partOf = [ "borgmatic.service" ];
          timerConfig.OnCalendar = "*-*-* 05:00:00";
        };
      };

    }
  );
}
