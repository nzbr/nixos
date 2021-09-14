{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./common.nix

    ./common/java.nix

    ./desktop/theme
    ./desktop/pulseaudio.nix
    ./desktop/device/razer.nix
    ./desktop/device/razer-nari.nix
    ./desktop/plymouth
  ];

  environment.systemPackages = with pkgs; [
    unstable.vivaldi
    unstable.vivaldi-widevine
    unstable.vivaldi-ffmpeg-codecs

    vlc
    spotify

    discord
    unstable.element-desktop
    signal-desktop

    libreoffice-fresh

    xsel

    remmina
    virt-manager
    x2goclient

    lm_sensors
  ];

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    roboto
    roboto-slab
    roboto-mono
  ];

  services = {
    xserver = {
      enable = true;
      libinput.enable = true;
      layout = "eu";
    };

    teamviewer.enable = true;
    flatpak.enable = true;
  };

  xdg.portal.enable = true;

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
  users.users.nzbr.extraGroups = [ "networkmanager" ];

  # boot.kernelPackages = pkgs.unstable.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_zen;
}
