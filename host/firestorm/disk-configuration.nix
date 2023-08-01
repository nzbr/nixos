{ ... }:
let
  disk = "/dev/sda";
in
with builtins; {
  disko.devices = {
    disk.${disk} = {
      device = disk;
      type = "disk";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "ESP";
            start = "0";
            end = "4GiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "root";
            start = "4GiB";
            end = "-32GiB";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          }
          {
            name = "swap";
            start = "-32GiB";
            end = "100%";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          }
        ];
      };
    };
    zpool.zroot = {
      type = "zpool";
      rootFsOptions = {
        canmount = "off";
        mountpoint = "none";
        encryption = "aes-256-gcm";
        keyformat = "passphrase";
        keylocation = "prompt";
        acltype = "posixacl";
        snapdev = "visible";
      };
      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        nix-store = {
          type = "zfs_fs";
          mountpoint = "/nix/store";
          options = {
            mountpoint = "legacy";
            compression = "lz4";
            atime = "off";
          };
        };
        kubernetes = {
          type = "zfs_fs";
          mountpoint = "/storage/kubernetes";
          options.mountpoint = "legacy";
        };
        kadalu = {
          type = "zfs_volume";
          size = "100GiB";
          content = {
            type = "filesystem";
            format = "xfs";
          };
        };
        reserved = {
          options = {
            canmount = "off";
            mountpoint = "none";
            reservation = "5GiB";
          };
          type = "zfs_fs";
        };
      };
    };
  };
}
