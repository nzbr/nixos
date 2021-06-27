{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "earthquake";

  imports = [
    ../module/common/boot/systemd-boot.nix
    ../module/common/service/syncthing.nix
    ../module/common/service/wireguard.nix
    ../module/server.nix
    ../module/server/service/k3s.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "hid_roccat"
        "hid_roccat_common"
        "hid_roccat_isku"

        "e1000e" # Early boot network
      ];
      kernelModules = [];
    };
    kernelModules = [ "dm-snapshot" "kvm-intel" ];
    extraModulePackages = [ ];
  };

  environment.etc."lukskey" = {
    source = ../secret + "/${config.networking.hostName}/lukskey";
    mode = "0400";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@" "ssd" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      device = "/dev/mapper/cr_root";
      fsType = "btrfs";
      options = [ "subvol=@/nix/store" "ssd" "noatime" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/799C-AA37";
      fsType = "vfat";
      neededForBoot = true;
      noCheck = true;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
    "/storage" =
    let label = "cr_storage";
    in {
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
    "/storage/Backup" =
    let label = "cr_backup";
    in {
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
    "/var/lib/rancher/k3s/storage" = {
      device = "/storage/kubernetes/local-path";
      options = [ "bind" ];
    };
    "/var/lib/longhorn" = {
      device = "/storage/kubernetes/longhorn";
      options = [ "bind" ];
    };
  };

  boot.initrd = {
    luks.devices = {
      "cr_root" = {
        device = "/dev/disk/by-uuid/13187d61-8666-4533-b853-fd32e20eed2c";
        preLVM = true;
      };
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/64f798e8-2382-4d82-9591-5616d368c30e";
      randomEncryption = {
        enable = true;
      };
    }
  ];

  networking = {
    useNetworkd = true;
    defaultGateway = "10.42.2.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
    interfaces.eno1 = {
      ipv4.addresses = [{
        address = "10.42.2.3";
        prefixLength = 24;
      }];
    };
  };

  services.syncthing.dataDir = "/storage/NAS/nzbr";
  services.syncthing.declarative.folders.mp3.path = lib.mkForce "/storage/NAS/Media/MP3";

  users.groups."media".members = [
    "nzbr"
  ];

  services.samba = {
    enable = true;
    enableNmbd = true;
    enableWinbindd = true;
    nsswins = true;
    syncPasswordsByPam = true;

    extraConfig = ''
      workgroup = WORKGROUP
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}
      security = user
      hosts allow = 10.42.0.0/16 localhost
      hosts deny = 0.0.0.0/0 ::/0
      guest account = nobody
      map to guest = bad user
    '';

    shares = {
      nzbr = {
        path = "/storage/NAS/nzbr";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "nzbr";
      };
      Media = {
        path = "/storage/NAS/Media";
        browseable = "yes";
        public = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force group" = "media";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 445 139 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];

  nzbr.wgIp = "10.42.0.2";
  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.42.0.2/24"
      "fd42:42::7a24:afff:febc:c07/64"
    ];
    peers = [
      { # storm
        publicKey = (lib.fileContents ../secret/storm/wireguard/public.key);
        endpoint = "storm6.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.0/26"
          "fd42:42::/32"
          "172.18.0.0/16" # storm's Docker network
        ];
      }
      { # avalanche
        publicKey = (lib.fileContents ../secret/avalanche/wireguard/public.key);
        endpoint = "avalanche6.nzbr.de:51820";
        allowedIPs = [
          "10.42.0.4/32"
          "fd42:42::88fc:d9ff:fe45:ead8/128"
        ];
      }
    ];
  };
}
