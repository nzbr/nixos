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

    installer.sdcard = {
      enable = true;
      aarch64 = {
        enable = true;
      };
    };

    agenix.enable = false;
  };

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 3;
        firmwareConfig = ''
          dtparam=audio=on
        '';
      };
    };
    initrd = {
      kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
    };
    kernelModules = [
      "bcm2835-v4l2"
    ];
    kernelParams = [
      "console=ttyS1,115200n8"
    ];
  };

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
    wireless.enable = true;
    firewall.enable = mkForce false;
    interfaces.eth0.useDHCP = true;
  };

  environment.systemPackages = with pkgs; [
    dhcpcd
    libraspberrypi
  ];

  virtualisation.docker.enable = mkForce false;
}
