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
      gitlab-runner = {
        enable = true;
        extraTags = [ "kube-deploy" ];
      };
      borgbackup = {
        enable = true;
        # rcloneRemote = "jotta-archive";
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
          # {
          #   name = "zbackup";
          #   mountpoint = "/backup";
          #   recursive = true;
          # }
        ];
        paths = [
          "/dev/zvol/hoard/*@${config.nzbr.service.borgbackup.zfs.snapshotName}"
          "/dev/zvol/hoard/libvirt/*@${config.nzbr.service.borgbackup.zfs.snapshotName}"
        ];
        healthcheckUrl = "https://hc-ping.com/f904595a-cd31-4261-b714-21b14be2cdc2";
      };
      urbackup = {
        enable = true;
        backupfolder = "/backup/UrBackup";
        dataset = {
          images = "zbackup/UrBackup/images";
          files = "zbackup/UrBackup/files";
        };
      };
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
    kernelModules = [ "dm-snapshot" "kvm-intel" ];
    supportedFilesystems = [ "zfs" ];
    extraModulePackages = [ ];
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

      "/run/.luks/cr_storage_1" = zfsOnLuks "cr_storage_1" "7e8de2a9-5cd0-4475-8a99-9d436604e639";
      "/run/.luks/cr_storage_2" = zfsOnLuks "cr_storage_2" "b3c32804-ab03-45cf-8e74-1e6f59969d5a";
      "/run/.luks/cr_storage_3" = zfsOnLuks "cr_storage_3" "b6bba72c-ceb4-4116-89bb-8a9197059600";

      "/run/.luks/cr_backup_1" = zfsOnLuks "cr_backup_1" "942c4a41-edcc-4a60-8528-42db7a782c44";
      "/run/.luks/cr_backup_2" = zfsOnLuks "cr_backup_2" "c1261cce-9627-42c0-91a2-c36a534d76a6";
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
      "/var/lib/rancher/k3s/storage" = {
        from = "/storage/kubernetes/local-path";
        wantedBy = [ "k3s.service" ];
      };
      "/var/lib/libvirt" = {
        from = "/storage/libvirt";
        wantedBy = [ "libvirtd.service" ];
      };
      "/var/lib/machines" = {
        from = "/storage/machines";
      };
    };

  boot.zfs.extraPools = [ "hoard" "zbackup" ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/36a4546f-0d97-4a1b-818a-9aa7bffa9df4";
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
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eno1 = {
      useDHCP = true;
    };
    tempAddresses = "disabled";
    dhcpcd.extraConfig = ''
      slaac hwaddr
    '';
  };

  services.syncthing.dataDir = "/storage/nzbr";
  services.syncthing.folders.mp3.path = lib.mkForce "/storage/media/MP3";

  users.groups."media" = {
    gid = 999;
    members = [ "nzbr" ];
  };

  services.samba = {
    enable = true;
    enableNmbd = true;
    enableWinbindd = true;
    nsswins = true;

    extraConfig = ''
      workgroup = WORKGROUP
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}
      security = user
      hosts allow = 10.0.0.0/16 2a02:908::/32 100.64.0.0/10 localhost
      hosts deny = 0.0.0.0/0 ::/0
      guest account = nobody
      map to guest = bad user
    '';

    shares = {
      Backup = {
        path = "/backup";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "nzbr";
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
      };
      tmp = {
        path = "/tmp/smb";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "create mask" = "0666";
        "directory mask" = "0777";
        "force group" = "users";
      };
    };
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

  nzbr.program.java.enable = true;

  services.ceph.osd.daemons = [ "2" ];

  services.k3s = {
    enable = true;
    role = "agent";
  };

  nzbr.everythingIndex = [
    { path = "/backup"; schedule = "*-*-* 04:00:00"; }
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
      dataDir = "/storage/postgres/${config.services.postgresql.package.psqlSchema}";
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
            ensurePermissions = {
              "DATABASE ${name}" = "ALL PRIVILEGES";
            };
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
    location = "/storage/postgres/backup";
    compression = "none";
    databases = config.services.postgresql.ensureDatabases;
  };
  age.secrets."postgres-setup.sql".owner = "postgres";

  networking.firewall.trustedInterfaces = [ "docker0" ];

  system.stateVersion = "21.11";
  nzbr.home.config.home.stateVersion = "22.05";
}
