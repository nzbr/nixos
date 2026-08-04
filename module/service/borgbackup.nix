{ config, lib, pkgs, options, ... }:
with builtins; with lib; {
  options.nzbr.service.borgbackup = with types; {
    enable = mkEnableOption "Borg Backups";
    backupBlockDevices = mkEnableOption "backing up raw block devices";
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
    excludeFromSnapshot = mkOption {
      description = "List of paths to exclude from the backup, gets prepended with the snapshot mount path";
      type = listOf str;
      default = [ ];
    };
    cephfs = {
      snapDir = mkOption {
        type = str;
        default = ".snap";
        description = "Virtual directory under which the cephfs client manages snapshots";
      };
      snapshotName = mkOption {
        type = str;
        default = "borgbackup";
        description = "Name of the ZFS snapshot to use for the backup";
      };
      directories = mkOption {
        type = listOf str;
        default = [ ];
        description = "CephFS mounted directories to backup";
      };
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
    extraConfig = mkOption {
      default = { };
      type = attrsOf anything;
    };
  };


  config = mkIf config.nzbr.service.borgbackup.enable (
    let
      cfg = config.nzbr.service.borgbackup;
      opt = options.nzbr.service.borgbackup;
      runDir = "/run/borg";
      rcloneCachePath = "${runDir}/rclone-cache";
      rcloneMountPath = "${runDir}/rclone-mount";
      repoPath = cfg.repoUrl or "${rcloneMountPath}/borg/${config.networking.hostName}";
      snapshotMountPath = "${runDir}/snapshot";
      specialFilesList = "${runDir}/special-files";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${rcloneCachePath} 0755 root root -"
      ];

      system.fsPackages = mkIf opt.rcloneRemote.isDefined [
        (pkgs.runCommand "mount.rclone" { } ''
          mkdir -p $out/bin
          ln -s ${pkgs.rclone}/bin/rclone $out/bin/mount.rclone
        '')
      ];

      fileSystems.${rcloneMountPath} =
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
            "cache-dir=${rcloneCachePath}"
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

      environment.etc."borgmatic/config.yaml".text = generators.toJSON { } (
        recursiveUpdate
          {
            exclude_caches = true;
            read_special = cfg.backupBlockDevices;
            encryption_passcommand = "cat ${config.nzbr.assets."backup.password"}";
            compression = "auto,zstd,9";
            checkpoint_interval = 300;
            lock_wait = 300;

            repositories = [
              { label = "repository"; path = repoPath; }
            ];

            source_directories = flatten [
              cfg.paths
              snapshotMountPath
            ];

            exclude_from = flatten [
              (optional cfg.backupBlockDevices specialFilesList)
            ];

            exclude_patterns = map (path: assert hasPrefix "/" path; "${snapshotMountPath}${path}") cfg.excludeFromSnapshot;

            keep_daily = 7;
            keep_weekly = 4;
            keep_monthly = 12;
            keep_yearly = 5;

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

            commands = [
              {
                before = "action";
                when = ["create"];
                run = [
                  (pkgs.writeShellScript "borg-pre-backup_snapshot" ''
                    set -euxo pipefail

                    umount -R ${snapshotMountPath} || true
                    mount --mkdir -t tmpfs tmpfs ${snapshotMountPath}

                    ${concatStringsSep "\n" (
                      map
                      (pool:
                        assert pool.recursive -> pool.subvols == [ ];
                        let
                          mountpoint =
                            if pool.mountpoint == null
                            then "${snapshotMountPath}/"
                            else "${snapshotMountPath}/${removePrefix "/" pool.mountpoint}";
                        in
                        ''
                          zfs destroy -r ${pool.name}@${cfg.zfs.snapshotName} || true
                          zfs snapshot -r ${pool.name}@${cfg.zfs.snapshotName}
                          ${pkgs.parted}/bin/partprobe
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

                    ${concatStringsSep "\n" (
                      map
                        (dir:
                          let
                            snapshot = "${dir}/${cfg.cephfs.snapDir}/${cfg.cephfs.snapshotName}";
                          in
                          ''
                          if [[ -d "${snapshot}" ]]; then
                            rmdir "${snapshot}"
                          fi
                          mkdir "${snapshot}"

                          mount --mkdir -o bind "${snapshot}" "${snapshotMountPath}${dir}"
                        '')
                        cfg.cephfs.directories
                    )}

                    ${optionalString cfg.backupBlockDevices (pkgs.writeShellScript "borg-pre-backup_find-special" ''
                      set -euxo pipefail
                      find ${snapshotMountPath} -xtype b,c,p,s -fprint ${specialFilesList}
                      echo "Excluding $(wc -l ${specialFilesList} | ${pkgs.gawk}/bin/awk '{print $1;}') special files"
                    '')}
                  '')
                ];
              }

              {
                after = "everything";
                when = ["create"];
                run = [
                  (pkgs.writeShellScript "borg-post-backup" ''
                    set -euxo pipefail
                    umount -R ${snapshotMountPath}

                    ${concatStringsSep "\n" (map
                      (dir: "rmdir '${dir}/${cfg.cephfs.snapDir}/${cfg.cephfs.snapshotName}'")
                      (reverseList cfg.cephfs.directories)
                    )}

                    ${concatStringsSep "\n" (map
                      (pool: "zfs destroy -r ${pool.name}@${cfg.zfs.snapshotName}")
                      (reverseList cfg.zfs.pools)
                    )}
                  '')
                ];
              }
            ];

            healthchecks.ping_url = cfg.healthcheckUrl;
          }
          cfg.extraConfig
      );

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
