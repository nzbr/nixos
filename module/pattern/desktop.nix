{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.desktop.enable = mkEnableOption "Default settings for desktop computers";

  config =
    let
      cfg = config.nzbr.pattern.desktop;
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

        network = {
          iwd.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        firefox

        vlc
        # spotify

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

      virtualisation.waydroid.enable = true;

      programs.gnupg.agent = {
        enable = true;
        enableBrowserSocket = true;
      };

      xdg.portal.enable = true;

      networking = {
        networkmanager = {
          enable = true;
          plugins = with pkgs; [
            networkmanager-openvpn
            networkmanager-openconnect
          ];
        };
      };
      users.groups.networkmanager.members = [ config.nzbr.user ];

      nzbr.home.autostart = [
        # Fix spotify being stuck in full screen when switching to a smaller display resolution
        (pkgs.writeShellScript "fix-spotify.sh" ''
          sed -i '/app.window/d' $HOME/.config/spotify/prefs
        '')
      ];

      # boot.kernelPackages = pkgs.unstable.linuxPackages_zen;
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
}
