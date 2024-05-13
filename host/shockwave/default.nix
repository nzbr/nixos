{ config, lib, pkgs, inputs, system, ... }:

with builtins; with lib; {

  nzbr = {
    system = "aarch64-linux";
    patterns = [ "common" ];

    deployment.targetHost = "shockwave.dragon-augmented.ts.net";

    agenix.enable = mkForce false;
    nopasswd.enable = true;

    service = {
      tailscale.enable = true;
    };
  };

  # Try to gc 16GiB if there are less than 16GiB left on /nix/store
  nix.settings = {
    min-free = 17179869184;
    max-free = 34359738368;
  };

  nixpkgs.config.platform = mkDefault lib.systems.platforms.raspberrypi3;

  users.users.root.hashedPassword = "$y$j9T$VGAVooFVZ7SlGatJf/jpv1$PvWfQwQwvtS8m9xXLZKjJZJiC/fJD/gvmOsfZZ3CVeB";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [ # Per default it wants to bundle things like AHCI, which are missing from the RPi kernel
      "usb_storage"
      "usbhid"
      "hid_roccat"
      "hid_roccat_common"
      "hid_roccat_isku"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/33f37880-1fc2-403b-b9af-5945e1113f13";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5053-F3DD";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  swapDevices = [{
    device = "/swapfile";
  }];

  system.stateVersion = "23.11";
  nzbr.home.config.home.stateVersion = "23.11";
}
