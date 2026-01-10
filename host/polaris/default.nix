{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/auto-brightness.nix
    ./modules/openauto.nix
    ./modules/plymouth.nix
  ];

  nzbr = {
    system = "aarch64-linux";
    user = "helmsman";
    patterns = [ ];

    deployment.targetHost = "polaris";

    boot.raspberrypi = {
      enable = true;
      config.all = {
        dtparam = [
          "audio=off"
          "spi=on"
          "i2c_arm=on"
          "krnbt=on" # Enable bluetooth on boot
        ];
        dtoverlay = lib.mkForce [
          "rpi-backlight"
          "rpi-display"
          "disable-bt"
          "vc4-fkms-v3d"
          "rpi-ft5406"
          "tsl2563"
        ];
        disable_splash = 1;
        force_turbo = 1;
        gpu_mem = 256;
      };
      extraFirmwareCommands =
        let
          tsl2563-dtbo = pkgs.runCommand "ts2563.dtbo" { } ''
            ${pkgs.dtc}/bin/dtc -I dts -O dtb ${./overlays/tsl2563.dtso} > $out
          '';
        in
        ''
          cp ${tsl2563-dtbo} $PWD/overlays/tsl2563.dtbo
        '';
    };

    agenix.enable = false;
    nopasswd.enable = true;

    service.ssh = {
      enable = true;
      authorizedSystems = [ "pulsar" ];
    };

    home.users = [ config.nzbr.user ];

  };

  # Try to gc 16GiB if there are less than 16GiB left on /nix/store
  nix.settings = {
    min-free = 17179869184;
    max-free = 34359738368;
  };

  # nixpkgs.config.platform = lib.systems.platforms.raspberrypi4;

  boot = {
    # loader = {
    #   generic-extlinux-compatible.enable = false;
    #   systemd-boot.enable = true;
    #   efi.canTouchEfiVariables = true;
    # };

    # kernelPackages = pkgs.linuxPackages;
    kernelPackages = pkgs.linuxKernel.rpiPackages.linux_rpi4; # Mainline does not support the Pi Touchscreen

    # initrd.includeDefaultModules = false; # NixOS tries to load ahci per default, which the RPi kernel does not have
    # initrd.availableKernelModules = [
    #   "usbhid"
    # ];
    kernelModules = [
      "vc4"
    ];

    kernelParams = [
      "dwc_otg.lpm_enable=0"
      "rootwait"
      "console=tty1"
      "consoleblank=0"
    ];


    # blacklistedKernelModules = [
    #   "snd_bcm2835"
    #   # TODO: Blacklist broadcom bluetooth module (and disable kernbt)
    # ];

    kernel.sysctl = {
      "vm.swappiness" = 1; # Avaoid swapping to the SD card when swap is enabled
      "kernel.sysrq" = 1;
    };

    # postBootCommands = ''
    #   ${pkgs.plymouth}/bin/plymouthd --mode=boot --pid-file=/run/plymouth/pid --attach-to-session
    #   ${pkgs.plymouth}/bin/plymouth show-splash
    # '';
  };

  fileSystems = {
    # Root partition does not matter anyway, because we're not using an initramfs
    "/" = lib.mkForce {
      device = "/dev/disk/by-partuuid/0d9dc7fb-38da-45d8-bd43-d20f49c95cd8";
      fsType = "ext4";
    };
    "/boot/firmware" = lib.mkForce {
      device = "/dev/disk/by-uuid/30F0-A3FA";
      fsType = "vfat";
      options = [ "ro" "fmask=0022" "dmask=0022" ];
    };
  };

  # TODO: Comment this out when swap is not needed anymore
  swapDevices = [{
    device = "/dev/disk/by-uuid/413768a1-88a8-4c6f-906b-ff31e6145903";
  }];

  hardware = {
    # deviceTree = {
    #   enable = true;
    #   name = "broadcom/bcm2711-rpi-4-b.dtb";
    # };
    # raspberry-pi."4" = {
    #   apply-overlays-dtmerge.enable = true;
    #   touch-ft5406.enable = true;
    #   backlight.enable = true;
    #   # i2c0.enable = true;
    #   # i2c1.enable = true;
    #   # fkms-3d.enable = true;
    #   xhci.enable = true;
    # };
    graphics.enable = true;
    bluetooth = {
      enable = true;
    };
    i2c.enable = true;
  };

  users.users.${config.nzbr.user} = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "adbusers" "wheel" ];
  };

  networking.dhcpcd.enable = false;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false; # Only takes up boot time. The system is offline most of the time anyway

  services.openssh.enable = true;

  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  # services.desktopManager.plasma5.mobile.enable = true;
  services.desktopManager.plasma6.enable = true;

  # services.cage = {
  #   enable = true;
  #   user = config.nzbr.user;
  #   program = "${pkgs.openDsh}/bin/dash";
  # };

  programs.xwayland.enable = lib.mkForce false;

  environment.systemPackages = [
    # pkgs.adw-gtk3
    # pkgs.phosh-mobile-settings
    # pkgs.epiphany
    # pkgs.gnome-console

    pkgs.easyeffects

    pkgs.waypipe
    pkgs.tmux
    pkgs.vim
  ];

  programs.adb.enable = true;

  # TODO: Ofono

  #TODO: Remove
  security.sudo.wheelNeedsPassword = false;

  systemd.services."NetworkManager-wait-online".enable = false;

  system.stateVersion = "25.05";
  nzbr.home.config.home.stateVersion = "25.05";
}
