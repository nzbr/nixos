{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./common.nix
    desktop/device/razer-nari.nix
    desktop/plymouth/plymouth.nix
  ];

  environment.systemPackages = with pkgs; [
    vivaldi vivaldi-widevine vivaldi-ffmpeg-codecs

    vlc
    spotify

    discord
    unstable.element-desktop

    libreoffice-fresh
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    roboto roboto-slab roboto-mono
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver = {
    enable = true;
    libinput.enable = true;
    layout = "de";
  };

  networking = {
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      packages = with pkgs; [
        networkmanager-openvpn
        networkmanager-openconnect
      ];
    };
  };

  boot.kernelPackages = pkgs.unstable.linuxPackages_zen;
}
