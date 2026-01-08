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

      # 8TB
      "/run/.luks/cr_backup_1" = zfsOnLuks "cr_backup_1" "7e8de2a9-5cd0-4475-8a99-9d436604e639";
      "/run/.luks/cr_backup_2" = zfsOnLuks "cr_backup_2" "b3c32804-ab03-45cf-8e74-1e6f59969d5a";
      "/run/.luks/cr_backup_3" = zfsOnLuks "cr_backup_3" "b6bba72c-ceb4-4116-89bb-8a9197059600";

      # 4TB
      "/run/.luks/cr_backup_4-a" = zfsOnLuks "cr_backup_4-a" "942c4a41-edcc-4a60-8528-42db7a782c44";
      "/run/.luks/cr_backup_4-b" = zfsOnLuks "cr_backup_4-b" "c1261cce-9627-42c0-91a2-c36a534d76a6";
    };

  boot.initrd.luks.devices."cr_root".device = "/dev/disk/by-uuid/f15e5ea7-4012-4b93-99dc-31f0891268fc";

  boot.zfs.extraPools = [ "zbackup" ];

  systemd.services.lvm-activate = rec {
    description = "Import LVM volumes";
    before = [ "zfs-import-zbackup.service" "zfs-import.target" ];
    wantedBy = before;
    script = "${pkgs.lvm2.bin}/bin/vgchange -ay";
    serviceConfig.Type = "oneshot";
  };

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
  environment.etc."zfs/zed.d/zed.rc".source = mkForce config.nzbr.assets."zed.rc";

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

  users.users =
    (
      mapListToAttrs
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
        )
    ) // {
      pulsar = {
        isNormalUser = true;
        shell = pkgs.bashInteractive;
        home = "/backup/pulsar";
      };
    };

  environment.systemPackages = with pkgs; [
    borgbackup
    rclone
  ];

  services.samba = {
    enable = true;
    enableNmbd = true;
    enableWinbindd = true;
    nsswins = true;

    settings.global = {
      "workgroup" = "WORKGROUP";
      "server string" = config.networking.hostName;
      "netbios name" = config.networking.hostName;
      "security" = "user";
      "hosts allow" = [ "10.0.0.0/16" "fd87:7593::/32" "100.64.0.0/10" "localhost" ];
      "hosts deny" = [ "0.0.0.0/0" "::/0" ];
      "guest account" = "nobody";
      "map to guest" = "bad user";
    };

    shares = {
      homes = {
        "browseable" = "no";
        "public" = "no";
        "read only" = "no";
        "create mode" = "0750";
        "acl allow execute always" = "yes";
        "map acl inherit" = "yes";
        "inherit acls" = "yes";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    445 # SMB
    137 # NetBIOS
    139
  ];
  networking.firewall.allowedUDPPorts = [
    137 # NetBIOS
    138
  ];

  # TODO: Upload from zfs snapshot
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
