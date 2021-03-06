{ config, lib, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
{
  networking.hostId = "b93ad358";

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "server" ];
    nodeIp = "100.71.200.40";

    boot = {
      grub.enable = true;
      remoteUnlock = {
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
        systems = [ "x86_64-linux" "i686-linux" ];
      };
      tailscale.enable = true;
      # ceph.enable = true;
      ddns = {
        enable = true;
        domain = "earthquake.nzbr.de";
      };
      gitlab-runner = {
        enable = true;
        extraTags = [ "kube-deploy" ];
      };
      restic = {
        enable = true;
        remote = "jotta-archive";
        include = [
          "zroot/etc"
          "zroot/home"
          "zroot/root"
          "zroot/srv"
          "zroot/var/lib/rancher/k3s"
          "zroot/var/lib/libvirt"

          "hoard"
        ];
        healthcheck = {
          backup = "https://hc-ping.com/f904595a-cd31-4261-b714-21b14be2cdc2";
          prune = "https://hc-ping.com/d9588269-0518-4804-8a8a-512c117954ab";
        };
        pools = [
          {
            name = "zroot";
          }
          {
            name = "hoard";
            subvols = [
              { name = "backup"; mountpoint = "/backup"; }
              { name = "chia"; mountpoint = "/chia"; }
              { name = "kubernetes"; mountpoint = "/kubernetes"; }
              { name = "libvirt"; mountpoint = "/libvirt"; }
              { name = "gitlab"; mountpoint = "/gitlab"; }
              { name = "media"; mountpoint = "/media"; }
              { name = "nzbr"; mountpoint = "/nzbr"; }
            ];
          }
        ];
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
      grub = {
        efiSupport = true;
        copyKernels = true;
      };
    };

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
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

  fileSystems = {
    "/" = {
      device = "zroot";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/C669-E056";
      fsType = "vfat";
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=16G" ];
    };

    "/run/.cr_storage/1" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "ro" "size=0" ];
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/7e8de2a9-5cd0-4475-8a99-9d436604e639";
        label = "cr_storage_1";
        keyFile = "/mnt-root/etc/lukskey";
      };
    };
    "/run/.cr_storage/2" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "ro" "size=0" ];
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/b3c32804-ab03-45cf-8e74-1e6f59969d5a";
        label = "cr_storage_2";
        keyFile = "/mnt-root/etc/lukskey";
      };
    };
    "/run/.cr_storage/3" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "ro" "size=0" ];
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/b6bba72c-ceb4-4116-89bb-8a9197059600";
        label = "cr_storage_3";
        keyFile = "/mnt-root/etc/lukskey";
      };
    };
    "/storage" = {
      device = "hoard";
      fsType = "zfs";
    };
    "/storage/backup" = {
      device = "hoard/backup";
      fsType = "zfs";
    };
    "/storage/chia" = {
      device = "hoard/chia";
      fsType = "zfs";
    };
    "/storage/kubernetes" = {
      device = "hoard/kubernetes";
      fsType = "zfs";
    };
    "/storage/libvirt" = {
      device = "hoard/libvirt";
      fsType = "zfs";
    };
    "/storage/gitlab" = {
      device = "hoard/gitlab";
      fsType = "zfs";
    };
    "/storage/media" = {
      device = "hoard/media";
      fsType = "zfs";
    };
    "/storage/nzbr" = {
      device = "hoard/nzbr";
      fsType = "zfs";
    };

    # OLD #
    "/old/storage" =
      let label = "cr_storage";
      in
      {
        device = "/dev/mapper/${label}";
        fsType = "btrfs";
        neededForBoot = false;
        encrypted = {
          enable = true;
          blkDev = "/dev/disk/by-uuid/38627a12-ce2f-43ac-9cfd-24fc20e00e26";
          label = label;
          keyFile = "/mnt-root/etc/lukskey";
        };
      };
    "/old/storage/Backup" =
      let label = "cr_backup";
      in
      {
        device = "/dev/mapper/${label}";
        fsType = "btrfs";
        neededForBoot = false;
        encrypted = {
          enable = true;
          blkDev = "/dev/disk/by-uuid/bdb010d6-48a2-4d59-b935-821dced8d912";
          label = label;
          keyFile = "/mnt-root/etc/lukskey";
        };
      };
  }
  //
  lib.mapAttrs'
    (to: from:
      {
        name = to;
        value = {
          device = from;
          options = [ "bind" ];
        };
      }
    )
    {
      "/var/lib/rancher/k3s/storage" = "/storage/kubernetes/local-path";
      "/var/lib/longhorn" = "/storage/kubernetes/longhorn";
      "/var/lib/etcd" = "/storage/kubernetes/etcd";
      "/var/lib/rook" = "/storage/kubernetes/rook";
      "/var/lib/ceph" = "/storage/ceph";
      "/var/lib/libvirt" = "/storage/libvirt";
    };

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

  users.groups."media".members = [
    "nzbr"
  ];

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
        path = "/storage/backup";
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
      };
      Media = {
        path = "/storage/media";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "media";
      };
      tmp = {
        path = "/tmp/smb";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "create mask" = "0660";
        "directory mask" = "0770";
        "force group" = "users";
      };
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /storage/media 10.0.0.2/32(rw)
    '';
  };

  systemd.tmpfiles.rules = [
    "d /tmp/smb 0770 nzbr users 1d"
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

}
