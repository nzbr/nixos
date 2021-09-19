{ config, lib, pkgs, modulesPath, root, ... }:
{
  networking.hostName = "earthquake";
  networking.hostId = "b93ad358";

  imports = [
    "${root}/module/common/java.nix"
    "${root}/module/common/boot/systemd-boot.nix"
    "${root}/module/common/service/libvirtd.nix"
    "${root}/module/common/service/syncthing.nix"
    "${root}/module/common/service/wireguard.nix"

    "${root}/module/server.nix"
    "${root}/module/server/restic.nix"
    "${root}/module/server/service/k3s.nix"
    "${root}/module/server/service/ddns.nix"

    "${root}/module/desktop/development.nix"
    # "${root}/module/desktop/gnome.nix"
    "${root}/module/desktop/latex.nix"
    "${root}/module/desktop/pulseaudio.nix"
    "${root}/module/desktop/theme"

    # "${root}/container/watchtower.nix"
    # "${root}/container/machinaris.nix"
  ];

  boot.loader.systemd-boot.configurationLimit = 1;

  boot = {
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
      device = "beach"; # -> zroot
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/C669-E056";
      fsType = "vfat";
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
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
      device = "hottub"; # -> hoard
      fsType = "zfs";
    };
    "/storage/backup" = {
      device = "hottub/backup";
      fsType = "zfs";
    };
    "/storage/chia" = {
      device = "hottub/chia";
      fsType = "zfs";
    };
    "/storage/kubernetes" = {
      device = "hottub/kubernetes";
      fsType = "zfs";
    };
    "/storage/libvirt" = {
      device = "hottub/libvirt";
      fsType = "zfs";
    };

    # OLD #
    "/old" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@" "ssd" ];
      neededForBoot = false;
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-uuid/13187d61-8666-4533-b853-fd32e20eed2c";
        label = "cr_root";
        keyFile = "/mnt-root/etc/lukskey";
      };
    };
    "/old/nix/store" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@/nix/store" "ssd" "noatime" ];
      neededForBoot = false;
    };
    "/old/boot" = {
      device = "/dev/disk/by-uuid/799C-AA37";
      fsType = "vfat";
      neededForBoot = false;
      noCheck = true;
    };
    "/old/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
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
      "/var/lib/libvirt" = "/storage/libvirt";
    };

  # boot.initrd = {
  #   luks.devices = {
  #     "cr_root" = {
  #       # /old
  #       device = "/dev/disk/by-uuid/13187d61-8666-4533-b853-fd32e20eed2c";
  #       preLVM = true;
  #     };
  #   };
  # };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/36a4546f-0d97-4a1b-818a-9aa7bffa9df4";
      randomEncryption = {
        enable = true;
      };
    }

    # OLD #
    {
      device = "/dev/disk/by-partuuid/64f798e8-2382-4d82-9591-5616d368c30e";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  nzbr.remote-unlock = {
    luks = false;
    zfs = [ "beach" ];
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
  services.syncthing.declarative.folders.mp3.path = lib.mkForce "/storage/media/MP3";

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
      hosts allow = 10.0.0.0/16 2a02:908::/32 localhost
      hosts deny = 0.0.0.0/0 ::/0
      guest account = nobody
      map to guest = bad user
    '';

    shares = {
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

  system.activationScripts.tmp-share-mkdir.text = ''
    mkdir -p /tmp/smb
    chown -R nzbr:users /tmp/smb
    chmod 0770 /tmp/smb
  '';

  networking.firewall.allowedTCPPorts = [
    445 # SMB
    137
    138
    139 # NetBIOS
  ];
  networking.firewall.allowedUDPPorts = [
    137
    138
    139 # NetBIOS
  ];

  nzbr.wgIp = "10.42.0.2";
  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.42.0.2/24"
      "fd42:42::7a24:afff:febc:c07/64"
    ];
    peers = [
      {
        # storm
        publicKey = (lib.fileContents config.nzbr.foreignAssets.storm."wireguard/public.key");
        endpoint = "storm.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.0/26"
          "fd42:42::/32"
          "172.18.0.0/16" # storm's Docker network
        ];
      }
      {
        # avalanche
        publicKey = (lib.fileContents config.nzbr.foreignAssets.avalanche."wireguard/public.key");
        endpoint = "avalanche.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.4/32"
          "fd42:42::88fc:d9ff:fe45:ead8/128"
        ];
      }
    ];
  };


  # Based on https://docs.pi-hole.net/guides/dns/unbound/
  # services.unbound =
  # let
  #   rootHints = builtins.fetchurl "https://www.internic.net/domain/named.root";
  # in {
  #   enable = true;
  #   extraConfig = ''
  #     # server:
  #       verbosity: 0
  #       port: 5353

  #       do-ip4: yes
  #       do-ip6: yes
  #       do-udp: yes
  #       do-tcp: yes
  #       prefer-ip6: yes

  #       # root-hints: "${rootHints}"
  #       root-hints: "/etc/unbound/named.root"

  #       harden-glue: yes
  #       harden-dnssec-stripped: yes
  #       use-caps-for-id: no
  #       edns-buffer-size: 1472

  #       prefetch: yes

  #       num-threads: 1
  #       so-rcvbuf: 1m

  #       private-address: 192.168.0.0/16
  #       private-address: 169.254.0.0/16
  #       private-address: 172.16.0.0/12
  #       private-address: 10.0.0.0/8
  #       private-address: fd00::/8
  #       private-address: fe80::/10
  #   '';
  # };
  # networking.resolvconf.useLocalResolver = false;

  # BACKUPS #
  nzbr.restic = {
    remote = "jotta-archive";
    include = [
      "beach/etc"
      "beach/home"
      "beach/root"
      "beach/srv"

      "hottub/backup"
      "hottub/chia/config"
      "hottub/kubernetes"
      "hottub/libvirt"
      "hottub/media"
      "hottub/nzbr"
    ];
    healthcheck = {
      backup = "https://hc-ping.com/f904595a-cd31-4261-b714-21b14be2cdc2";
      prune = "https://hc-ping.com/d9588269-0518-4804-8a8a-512c117954ab";
    };
    pools = [
      {
        name = "beach";
      }
      {
        name = "hottub";
        subvols = [
          { name = "backup"; mountpoint = "/backup"; }
          { name = "chia"; mountpoint = "/chia"; }
          { name = "kubernetes"; mountpoint = "/kubernetes"; }
          { name = "libvirt"; mountpoint = "/libvirt"; }
        ];
      }
    ];
  };

  # Modprobe config for macOS VM
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  nzbr.ddns = {
    enable = true;
    domain = "earthquake.nzbr.de";
  };

  # remote desktop
  programs.x2goserver = {
    enable = true;
    superenicer.enable = true;
  };
  services.xrdp = {
    enable = true;
    # defaultWindowManager = "${pkgs.gnome3.gnome-session}/bin/gnome-session";
    # defaultWindowManager = "${pkgs.lxterminal}/bin/lxterminal";
    defaultWindowManager = "${pkgs.plasma-workspace}/bin/startplasma-x11";
  };

  environment.systemPackages = with pkgs; [
    unstable.vivaldi
    unstable.vivaldi-widevine
    unstable.vivaldi-ffmpeg-codecs
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    roboto
    roboto-slab
    roboto-mono
  ];

  # services.xserver.displayManager.gdm.enable = lib.mkForce false;
  # services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
  # services.xserver.desktopManager.lxqt.enable = true;
  # services.xserver.windowManager.openbox.enable = true;
  # services.xserver.windowManager.metacity.enable = true;
  services.xserver.desktopManager.plasma5 = {
    enable = true;
    phononBackend = "vlc";
  };

  xdg.portal.enable = true;

  networking.networkmanager.enable = lib.mkForce false;
}
