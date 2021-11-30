{ config, lib, inputs, pkgs, modulesPath, ... }:
let
  host = config.nzbr.flake.host;
in
{
  networking.hostName = "meteor";

  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/t420"
  ];

  nzbr = {
    patterns = [ "common" "desktop" "laptop" "development" "hapra" "gaming" ];
    pattern.development.guiTools = true;

    program = {
      latex.enable = true;
      mullvad.enable = true;
    };

    service = {
      printing.enable = true;
      syncthing.enable = true;
      tailscale.enable = true;
    };
  };

  boot = {
    loader.systemd-boot.enable = true;

    initrd = {
      availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
      kernelModules = [ ];

      luks.devices = {
        "cr_root" = {
          device = "/dev/disk/by-uuid/d97c7f38-11ff-413e-80af-0cbe3966a7d5";
        };
        "cr_home" = {
          device = "/dev/disk/by-uuid/ccb4975c-9668-4389-9ed8-3d6d6f42d7d1";
        };
      };
    };

    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "systemd.unit=multi-user.target" ];
    extraModulePackages = [ ];

    resumeDevice = "/dev/vg_root/swap";
  };

  fileSystems = {
    "/" = {
      device = "/dev/vg_root/root";
      fsType = "btrfs";
      options = [ "ssd" "discard=async" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/C424-EF2E";
      fsType = "vfat";
      neededForBoot = true;
    };
    "/home" = {
      device = "/dev/vg_home/home";
      fsType = "btrfs";
      neededForBoot = false;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
  };

  swapDevices = [
    { device = config.boot.resumeDevice; }
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.plymouth.enable = lib.mkForce false; # Does not work with proprietary nvidia driver @future me: Lass das so, wenn du willst, dass der Laptop noch bootet!

  # Backlight (doesn't work yet?)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  '';

  # Fan controller
  boot.extraModprobeConfig = ''
    options thinkpad_acpi fan_control=1
  '';
  services.thinkfan = {
    enable = true;
    sensors = [
      { query = "/run/thinkfan/temp1_input"; type = "hwmon"; }
      { query = "/run/thinkfan/temp2_input"; type = "hwmon"; }
      { query = "/run/thinkfan/temp3_input"; type = "hwmon"; }
      { query = "/run/thinkfan/temp4_input"; type = "hwmon"; }
      { query = "/run/thinkfan/temp5_input"; type = "hwmon"; }
    ];
  };
  systemd.services.thinkfan.preStart = ''
    ln -sfT /sys/devices/platform/coretemp.0/hwmon/hwmon* /run/thinkfan
  '';

  systemd.services.delayed-gui-hack = {
    wantedBy = [ "multi-user.target" ];
    after = [ "getty.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! cat /proc/cmdline | grep -q nogui && ! systemctl status graphical.target >/dev/null; then
        sleep 5s
        exec systemctl start graphical.target
      fi
    '';
  };
}
