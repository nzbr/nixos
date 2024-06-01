{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  networking.hostId = "8c979594";

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];

    deployment.targetHost = "permafrost.dragon-augmented.ts.net";

    boot = {
      remoteUnlock = {
        enable = true;
        tailscale = true;
        luks = true;
      };
    };

    service = {
      tailscale = {
        enable = true;
      };
    };
  };

  boot = {
    loader = {
      efi = {
        efiSysMountPoint = "/boot";
      };
      systemd-boot.enable = true;
    };

    initrd = {
      kernelModules = [
        "r8169" # Early boot network
      ];
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "hid_roccat"
        "hid_roccat_common"
        "hid_roccat_isku"
      ];
      supportedFilesystems = [ "zfs" ];
    };
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "zfs" ];
  };

  environment.etc."lukskey" = {
    source = config.nzbr.assets."lukskey";
    mode = "0400";
  };

  fileSystems =
    let
      zfsOnLuks = name: uuid: {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "ro" "size=0" ];
        encrypted = {
          enable = true;
          blkDev = "/dev/disk/by-uuid/${uuid}";
          label = name;
          keyFile = "/mnt-root/etc/lukskey";
        };
      };
    in
    {
      "/" = {
        device = "/dev/mapper/cr_root";
        fsType = "xfs";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/D6F4-5103";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
      "/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "size=16G" ];
      };

      "/run/.luks/cr_backup_1" = zfsOnLuks "cr_backup_1" "dccfeafa-2221-4566-a280-7c3e89ca8b75";
      "/run/.luks/cr_backup_2" = zfsOnLuks "cr_backup_2" "723a5e4d-b2d8-4369-ab25-c8b40d21a6aa";
      "/run/.luks/cr_backup_3" = zfsOnLuks "cr_backup_3" "251b2027-7540-456f-bf47-81daecf5c142";
      "/run/.luks/cr_backup_4" = zfsOnLuks "cr_backup_4" "d6f7f7b3-ddde-4250-beea-cf95800e4567";
      "/run/.luks/cr_backup_5" = zfsOnLuks "cr_backup_5" "96a41325-288c-4fae-bcc5-a9fe75c410e9";
      "/run/.luks/cr_backup_6" = zfsOnLuks "cr_backup_6" "f79f11cf-dc0d-4ff1-ae15-fa96f4d07783";
    };

  boot.initrd.luks.devices."cr_root".device = "/dev/disk/by-uuid/f15e5ea7-4012-4b93-99dc-31f0891268fc";

  boot.zfs.extraPools = [ "zbackup" ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/5b42f06e-fe01-4c46-a69c-b5dfd1f8ebf4";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  networking = {
    useDHCP = true;
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.enp5s0 = {
      useDHCP = true;
    };
    tempAddresses = "disabled";
    dhcpcd.extraConfig = ''
      slaac hwaddr
    '';
  };

  users.users = mapListToAttrs
    (host: {
      name = host;
      value = {
        isNormalUser = true;
        shell = pkgs.bashInteractive;
        home = "/backup/${host}";
        openssh.authorizedKeys.keyFiles = [ config.nzbr.foreignAssets.${host}."ssh/permafrost.pub" ];
      };
    })
    (filter
      (host: config.nzbr.foreignAssets.${host} ? "ssh/permafrost.pub")
      (builtins.attrNames config.nzbr.foreignAssets)
    );

  environment.systemPackages = with pkgs; [
    borgbackup
    rclone
  ];

  # TODO: Add monitoring for this
  systemd = {
    services.upload =
    let
      hc-id = "1766fc92-dd2b-46b0-afe8-a692118e8ab0";
    in
    {
      description = "Upload backups to remote";
      after = [ "network.target" ];
      environment = {
        HOME = "/root";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.curl}/bin/curl -fs -m 10 --retry 5 -o /dev/null https://hc-ping.com/${hc-id}/start";
        ExecStart = "${pkgs.rclone}/bin/rclone sync -vv /backup jotta-archive:permafrost";
        ExecStartPost = "${pkgs.curl}/bin/curl -fs -m 10 --retry 5 -o /dev/null https://hc-ping.com/${hc-id}";
      };
    };
    timers.upload = {
      wantedBy = [ "timers.target" ];
      partOf = [ "upload.service" ];
      timerConfig.OnCalendar = "*-*-* 02:00:00";
    };
  };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}
