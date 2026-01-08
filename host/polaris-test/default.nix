{ config, lib, pkgs, ... }:

{
  imports = [
    ../polaris/modules/plymouth.nix
  ];

  nzbr = {
    system = "x86_64-linux";
    user = "helmsman";
    patterns = [ ];

    deployment.targetHost = "polaris-test";

    agenix.enable = false;
    nopasswd.enable = true;

    service.ssh = {
      enable = true;
      authorizedSystems = [ "pulsar" ];
    };

  };

  # Try to gc 16GiB if there are less than 16GiB left on /nix/store
  nix.settings = {
    min-free = 17179869184;
    max-free = 34359738368;
  };

  # nixpkgs.config.platform = lib.systems.platforms.raspberrypi4;

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };

    kernelPackages = pkgs.linuxPackages;

    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "ehci_pci"
      "ahci"
      "vmw_pvscsi"
      "sd_mod"
      "sr_mod"
    ];

    kernelParams = [
      "dwc_otg.lpm_enable=0"
      "rootwait"
      "console=tty1"
      "consoleblank=0"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 1; # Avaoid swapping to the SD card when swap is enabled
      "kernel.sysrq" = 1;
    };
  };

  fileSystems = {
    # Root partition does not matter anyway, because we're not using an initramfs
    "/" = lib.mkForce {
      device = "/dev/disk/by-uuid/4484387d-8792-48f7-beb6-d54f9fad33e9";
      fsType = "ext4";
    };
  };

  swapDevices = [{
    device = "/dev/disk/by-uuid/3c551f4d-ed9e-48a4-8777-9cfc47d16af3";
  }];

  virtualisation.vmware.guest.enable = true;

  hardware = {
    graphics.enable = true;
    bluetooth = {
      enable = true;
    };
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

  services.xserver = {
    enable = true;
    # displayManager.sddm = {
    #   enable = true;
    #   wayland.enable = true;
    # };
    desktopManager.plasma6.enable = true;
  };
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;

  programs.xwayland.enable = lib.mkForce false;

  environment.systemPackages = [
    pkgs.openauto
    pkgs.openDsh
    pkgs.openautoLauncher

    pkgs.easyeffects

    pkgs.waypipe
    pkgs.tmux
    pkgs.vim
  ];

  nixpkgs.overlays = [
    (final: prev: {
      h264bitstream = prev.callPackage ../polaris/pkgs/h264bitstream.nix { };
      aasdk = prev.callPackage ../polaris/pkgs/aasdk.nix { inherit (final) openDsh; };
      qtgstreamer = prev.libsForQt5.callPackage ../polaris/pkgs/qtgstreamer.nix { };
      openauto = prev.libsForQt5.callPackage ../polaris/pkgs/openauto.nix { inherit (final) aasdk h264bitstream qtgstreamer; };
      openDsh = prev.libsForQt5.callPackage ../polaris/pkgs/openDsh.nix { inherit (final) openauto aasdk; };
      openautoLauncher = prev.callPackage ../polaris/pkgs/launcher.nix { inherit (final) openauto openDsh; };
    })
  ];

  system.build.aasdk = pkgs.aasdk;
  system.build.openauto = pkgs.openauto;
  system.build.h264bitstream = pkgs.h264bitstream;
  system.build.qtgstreamer = pkgs.qtgstreamer;
  system.build.openDsh = pkgs.openDsh;

  programs.adb.enable = true;

  # TODO: Ofono

  #TODO: Remove
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
  nzbr.home.config.home.stateVersion = "25.05";
}
