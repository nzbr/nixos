{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  networking.hostName = "openauto";

  nzbr = {
    system = "aarch64-linux";
    patterns = [ "common" ];

    deployment = {
      targetHost = "10.0.91.113";
      substituteOnDestination = false;
    };

    channels.enable = mkForce false;
    nopasswd.enable = true;

    boot.raspberrypi = {
      enable = true;
      config.all = {
        dtparam = [
          "audio=off"
          "spi=on"
          "i2c_arm=on"
        ];
        dtoverlay = [
          "rpi-backlight"
          "rpi-display"
          "disable-bt"
          "vc4-fkms-v3d"
          "rpi-ft5406"
        ];
        disable_splash = 1;
        force_turbo = 1;
        gpu_mem = 256;
      };
    };

    installer.sdcard = {
      enable = true;
    };

    agenix.enable = false;
  };

  boot = {
    binfmt.emulatedSystems = [ "armv7l-linux" "armv6l-linux" ]; # Enable comiling comptible arm architectures

    kernelPackages = pkgs.linuxKernel.rpiPackages.linux_rpi3;
    kernelModules = [
      "vc4"
      "bcm2835_dma"
      "i2c_bcm2835"
      "bcm2835-v4l2"
    ];
    kernelParams = [
      "dwc_otg.lpm_enable=0"
      "rootwait"
      "console=ttyS1,115200"
    ];
  };

  nixpkgs.config.platform = lib.systems.platforms.raspberrypi3;

  sound.enable = true;

  hardware = {
    pulseaudio.enable = true;
    enableRedistributableFirmware = true;
  };

  networking = {
    firewall.enable = mkForce false;
    networkmanager.enable = true;
  };

  environment.systemPackages = with pkgs; [
    dhcpcd
    libraspberrypi
  ];

  services.xserver = {
    enable = true;
    desktopManager.lxqt.enable = true;
    displayManager.lightdm.enable = true;
  };
}
