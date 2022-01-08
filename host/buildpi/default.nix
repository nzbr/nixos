{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  nzbr = {
    system = "aarch64-linux";
    patterns = [ "common" ];

    agenix.enable = mkForce false;
    channels.enable = mkForce false;
    nopasswd.enable = true;

    boot = {
      raspberrypi = {
        enable = true;
        config = {
          pi4 = {
            arm_boost = 1;
          };
        };
      };
    };

    installer.sdcard.enable = true;

    service = {
      tailscale.enable = true;
      buildServer = {
        enable = true;
        maxJobs = 4;
        systems = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
      };
    };
  };

  nix.gc.automatic = mkForce false; # Reduce writes to the sd card

  boot.kernelPackages = pkgs.linuxKernel.rpiPackages.linux_rpi4;
  nixpkgs.config.platform = lib.systems.platforms.raspberrypi4;

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=3G" ];
  };

  networking.interfaces.eth0.useDHCP = true;

  environment.systemPackages = with pkgs; [
    dhcpcd
    libraspberrypi
  ];
}
