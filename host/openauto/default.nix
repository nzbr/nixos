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

  users.users = {
    "${config.nzbr.user}".passwordFile = mkForce null;
    root.passwordFile = mkForce null;
  };
  services.getty.autologinUser = lib.mkForce config.nzbr.user;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
  security.sudo.wheelNeedsPassword = false;

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
    displayManager = {
      autoLogin = {
        enable = true;
        inherit (config.nzbr) user;
      };
      lightdm.enable = true;
    };
  };
}
