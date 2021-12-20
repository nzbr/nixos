{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  nzbr = {
    system = "aarch64";
    patterns = [ "common" ];

    deployment = {
      targetHost = "10.0.91.113";
      substituteOnDestination = false;
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

  sound.enable = true;

  hardware = {
    pulseaudio.enable = true;
    enableRedistributableFirmware = true;
  };

  networking = {
    wireless.enable = true;
    firewall.enable = mkForce false;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  virtualisation.docker.enable = mkForce false;
}
