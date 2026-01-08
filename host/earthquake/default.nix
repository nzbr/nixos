{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  networking.hostId = "b93ad358";

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];
    nodeIp = "100.71.200.40";
    nodeIp6 = "fd7a:115c:a1e0:ab12:4843:cd96:6247:c828";

    deployment.targetHost = "earthquake.dragon-augmented.ts.net";

    boot = {
      remoteUnlock = {
        enable = true;
        tailscale = true;
        luks = false;
        zfs = [ "zroot" ];
      };
    };

    container = {
      watchtower.enable = true;
      gitlab.enable = true;
    };

    network.k3s-firewall.enable = true;

    service = {
      buildServer = {
        enable = true;
        maxJobs = 8;
        systems = [ "x86_64-linux" ];
      };
      tailscale = {
        enable = true;
        exit = true;
        cert = true;
      };
      # ceph.enable = true;
      ddns = {
        enable = true;
        domain = "earthquake.nzbr.de";
      };
      gitlab-runner.enable = true;
      borgbackup = {
        enable = true;
        repoUrl = "ssh://permafrost-backup/backup/${config.networking.hostName}";
        zfs.pools = [
          {
            name = "zroot";
            mountpoint = "/";
            recursive = true;
          }
          {
            name = "hoard";
            mountpoint = "/storage";
            recursive = true;
          }
        ];
        paths = [
          "/dev/zvol/hoard/*@${config.nzbr.service.borgbackup.zfs.snapshotName}"
          "/dev/zvol/hoard/libvirt/*@${config.nzbr.service.borgbackup.zfs.snapshotName}"
        ];
        healthcheckUrl = "https://hc-ping.com/f904595a-cd31-4261-b714-21b14be2cdc2";
        excludeFromSnapshot = [
          "/storage/media"
        ];
      };
      # urbackup = {
      #   enable = true;
      #   backupfolder = "/backup/UrBackup";
      #   dataset = {
      #     images = "zbackup/UrBackup/images";
      #     files = "zbackup/UrBackup/files";
      #   };
      # };
      gogBackup = {
        enable = true;
        destination = "/storage/media/ROM/PC/GOG";
        platform = "all";
        language = "de+en";
        exclude = "patches";
        schedule = "monthly";
      };
    };

    program = {
      latex.enable = true;
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
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "mpt3sas"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "hid_roccat"
        "hid_roccat_common"
        "hid_roccat_isku"

        "e1000e" # Early boot network
      ];
      kernelModules = [ ];
      supportedFilesystems = [ "zfs" ];
    };
    kernelModules = [ "dm-snapshot" "kvm-intel" "nvidia" ];
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
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
        device = "zroot";
        fsType = "zfs";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/C669-E056";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
      "/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "size=16G" ];
      };

      "/run/.luks/cr_storage_1" = zfsOnLuks "cr_storage_1" "8f10e1ac-53df-452b-8036-dc957d346194";
      "/run/.luks/cr_storage_2" = zfsOnLuks "cr_storage_2" "b61c0648-cccd-41fd-9e1b-5f2331d3a71e";
      "/run/.luks/cr_storage_3" = zfsOnLuks "cr_storage_3" "dd8c521a-9539-480b-bfe6-49a0fe045016";
    };

  systemd.mounts = lib.mapAttrsToList
    (to: attrs:
      rec {
        what = attrs.from;
        where = to;
        type = "none";
        options = "bind";

        after = [ "zfs.target" ];
        wants = after;

        wantedBy = (attrs.wantedBy or [ ]) ++ [ "local-fs.target" ];
        before = wantedBy;
      }
    )
    {
      "/var/lib/libvirt" = {
        from = "/storage/libvirt";
        wantedBy = [ "libvirtd.service" ];
      };
      "/var/lib/machines" = {
        from = "/storage/machines";
      };
    };

  boot.zfs.extraPools = [ "hoard" ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/36a4546f-0d97-4a1b-818a-9aa7bffa9df4";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.opengl.enable = true;
  environment.systemPackages = with pkgs; [
    config.hardware.nvidia.package
    cudatoolkit
    (nvtopPackages.nvidia.override (args: { intel = true; }))
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };
  environment.etc."zfs/zed.d/zed.rc".source = mkForce config.nzbr.assets."zed.rc";

  networking = {
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eno1 = {
      useDHCP = true;
    };
    tempAddresses = "disabled";
    dhcpcd.extraConfig = ''
      slaac hwaddr
    '';
  };

  users.groups."media" = {
    gid = 999;
    members = [ "nzbr" ];
  };

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
      "hosts allow" = [ "10.0.0.0/16" "2a02:908::/32" "100.64.0.0/10" "localhost" ];
      "hosts deny" = [ "0.0.0.0/0" "::/0" ];
      "guest account" = "nobody";
      "map to guest" = "bad user";
    };

    shares = {
      Backup = {
        path = "/storage/backup";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "nzbr";
        "map acl inherit" = "yes";
        "inherit acls" = "yes";
      };
      nzbr = {
        path = "/storage/nzbr";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "nzbr";
        "acl allow execute always" = "yes";
        "map acl inherit" = "yes";
        "inherit acls" = "yes";
      };
      Media = {
        path = "/storage/media";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force group" = "media";
        "acl allow execute always" = "yes";
        "map acl inherit" = "yes";
        "inherit acls" = "yes";
      };
      tmp = {
        path = "/tmp/smb";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "create mask" = "0666";
        "directory mask" = "0777";
        "force group" = "users";
        "acl allow execute always" = "yes";
        "map acl inherit" = "yes";
        "inherit acls" = "yes";
      };
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /storage/media/ROM fd87:7593:4cee:0:695:bec:37c4:9734/64 (ro)
    '';
  };

  systemd.tmpfiles.rules = [
    "d /tmp/smb 0770 nzbr users 1d"
    "d /storage/postgres 0755 postgres users"
  ];

  networking.firewall.allowedTCPPorts = [
    445 # SMB
    137
    138
    139 # NetBIOS
    2049 # NFSv4
  ];
  networking.firewall.allowedUDPPorts = [
    137
    138
    139 # NetBIOS
    2049 # NFSv4
  ];
  networking.firewall.allowedUDPPortRanges = [{ from = 40000; to = 65535; }];

  # Modprobe config for macOS VM
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  nzbr.service.libvirtd.enable = true;

  nzbr.service.syncthing.enable = true;
  nzbr.service.syncthing.scanInterval = 24 * 3600;
  services.syncthing.dataDir = "/storage/nzbr";
  services.syncthing.settings.folders.mp3.path = lib.mkForce "/storage/media/MP3";

  nzbr.program.java.enable = true;

  services.ceph.osd.daemons = [ "2" ];

  services.k3s = {
    enable = true;
    role = "agent";
  };

  nzbr.everythingIndex = [
    { path = "/storage/backup"; schedule = "*-*-* 04:00:00"; }
    { path = "/storage/media"; schedule = "*-*-* 0/3:00:00"; }
    { path = "/storage/nzbr"; schedule = "*-*-* *:0/30:00"; }
  ];

  nixpkgs.overlays = [
    (self: super: {
      plex = super.unstable.plex;
    })
  ];
  services.plex = {
    enable = true;
    openFirewall = true;
    dataDir = "/storage/media/.plex";
    user = "nzbr";
    group = "media";
  };

  services.postgresql =
    let
      services = [
        "gitlab"
        "nextcloud"
      ];
    in
    {
      enable = true;
      package = pkgs.postgresql_14;
      enableTCPIP = true;
      authentication = ''
        host all all 10.42.0.0/24 md5
        host all all 10.12.0.0/16 md5
        host all all 172.17.0.0/16 md5
        host all all 100.64.0.0/10 md5
      '';
      ensureDatabases = services;
      ensureUsers =
        map
          (name: {
            inherit name;
            ensureDBOwnership = true;
          })
          services;
      initialScript = config.nzbr.assets."postgres-setup.sql";
    };

  # hopefully prevent postgres from breaking on every reboot
  systemd.services.postgresql.serviceConfig = {
    TimeoutStartSec = "infinity";
    TimeoutSec = mkForce 600;
  };
  services.postgresqlBackup = {
    enable = true;
    location = "/storage/backup/pg-backup";
    compression = "none";
    databases = config.services.postgresql.ensureDatabases;
  };
  age.secrets."postgres-setup.sql".owner = "postgres";

  services.audiobookshelf = {
    enable = true;
    package = pkgs.unstable.audiobookshelf;
    group = "media";
    host = config.nzbr.nodeIp;
    openFirewall = false;
    port = 8000;
  };

  networking.firewall.trustedInterfaces = [ "docker0" ];

  systemd.services.backup-media =
    let
      hc-id = "e7634aae-01b2-48a6-84cd-d99c76d24a29";
    in
    {
      description = "Backup media";
      after = [ "network.target" ];
      restartIfChanged = false;
      environment = {
        HOME = "/root";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.curl}/bin/curl -fs -m 10 --retry 5 -o /dev/null https://hc-ping.com/${hc-id}/start";
        ExecStart = "${pkgs.rclone}/bin/rclone sync -vv /storage/media media-encrypted:earthquake-media";
        ExecStartPost = "${pkgs.curl}/bin/curl -fs -m 10 --retry 5 -o /dev/null https://hc-ping.com/${hc-id}";
      };
    };
  systemd.timers.backup-media = {
    wantedBy = [ "timers.target" ];
    partOf = [ "backup-media.service" ];
    timerConfig.OnCalendar = "*-*-* 02:00:00";
  };

  system.stateVersion = "21.11";
  nzbr.home.config.home.stateVersion = "22.05";
}
