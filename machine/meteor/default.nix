{ config, lib, inputs, pkgs, modulesPath, root, host, ... }:
{
  networking.hostName = "meteor";

  imports = [
    "${inputs.nixos-hardware}/lenovo/thinkpad/t420"

    "${root}/module/common/boot/grub.nix"
    "${root}/module/common/service/printing.nix"
    "${root}/module/common/service/syncthing.nix"

    "${root}/module/laptop.nix"
    "${root}/module/desktop/development.nix"
    "${root}/module/desktop/gaming.nix"
    "${root}/module/desktop/gnome.nix"
    "${root}/module/desktop/latex.nix"
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    # loader.grub.configurationLimit = 5;

    initrd = {
      availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" "f2fs" "xfs" ];
      kernelModules = [ ];

      luks.devices = {
        "cr_root" = {
          device = "/dev/disk/by-uuid/4fe2eb8b-ff38-42b1-8e23-a9fcadd899c5";
          keyFile = "/lukskey";
        };
        "cr_home" = {
          device = "/dev/disk/by-uuid/ccb4975c-9668-4389-9ed8-3d6d6f42d7d1";
          keyFile = "/lukskey";
        };
      };
      # secrets = {

      # };
      # preDeviceCommands = ''
      #   set -x
      #   ${pkgs.rage}/bin/rage -i /ssh_host_ed25519_key -o /lukskey -d /lukskey.age
      #   set +x
      # '';
    };

    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "systemd.unit=multi-user.target" ];
    extraModulePackages = [ ];

    # TODO: resumeDevice
  };

  nzbr.initrdSecrets = {
    "ssh_host_ed25519_key" = "/etc/ssh/ssh_host_ed25519_key";
    "lukskey" = "${host}/lukskey.age";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cr_root";
      fsType = "f2fs";
      neededForBoot = true;
    };
    "/home" = {
      device = "/dev/mapper/cr_home";
      fsType = "xfs";
      neededForBoot = false;
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
  };

  swapDevices = [
    { device = "/swapfile"; }
  ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
  # services.xserver.videoDrivers = [ "nvidiaLegacy390" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.plymouth.enable = lib.mkForce false; # Does not work with proprietary nvidia driver

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

  nzbr.mullvad.enable = true;
}
