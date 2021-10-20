{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.desktop.enable = mkEnableOption "Default settings for desktop computers";

  config =
    let
      cfg = config.nzbr.pattern.laptop;
    in
    mkIf cfg.enable {

      nzbr = {
        program.java.enable = true;

        boot = {
          plymouth.enable = mkDefault true;
        };

        device = {
          razerChroma.enable = mkDefault true;
          razerNari.enable = true;
        };

        desktop = {
          gnome.enable = true;
          pulseaudio.enable = true;
        };
      };

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
        pcscd.enable = true;
      };

      programs.gnupg.agent = {
        enable = true;
        enableBrowserSocket = true;
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
      users.groups.networkmanager.members = [ config.nzbr.user ];

      # boot.kernelPackages = pkgs.unstable.linuxPackages_zen;
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
}
