{ config, lib, pkgs, root, sys, ... }:
{
  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file://${root}/secret/common/Starfield2.png";
      primary-color = "#000000";
      secondary-color = "#ffffff";
      show-desktop-icons = false;
    };
    "org/gnome/desktop/interface" = {
      gtk-theme = "Pop-dark";
      icon-theme = "Papirus-Dark";
    };
    "org/gnome/desktop/session" = {
      idle-delay = 0;
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false;
      power-button-action = "suspend";
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-timeout = 1800;
      sleep-inactive-battery-type = "hibernate";
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "arcmenu@arcmenu.com"
        "audio-switcher@albertomosconi"
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        "dash-to-panel@jderose9.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "gsconnect@andyholmes.github.io"
        "hibernate@dafne.rocks"
        "syncthingicon@jay.strict@posteo.de"
        "trayIconsReloaded@selfmade.pl"
        "tweaks-system-menu@extensions.gnome-shell.fifi.org"
      ];
      favorite-apps = [ "vivalid-stable.desktop" "org.gnome.Nautilus.desktop" "org.gnome.Terminal.desktop" "code.desktop" "idea-ultimate.desktop" "gitkraken.desktop" "insomnia.desktop" "timeular.desktop" "discord.desktop" "spotify.desktop" ];
      welcome-dialog-last-shown-version = "40.1";
    };
    "org/gnome/shell/extensions/arcmenu" = {
      arc-menu-icon = 7;
      arc-menu-placement = "DTP";
      available-placement = [false true false];
      # custom-menu-button-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
      custom-menu-button-icon = "${root}/secret/common/Start.png";
      custom-menu-button-icon-size = 24;
      custom-menu-button-text = "";
      default-menu-view = "Frequent_Apps";
      distro-icon = 1;
      enable-custom-arc-menu = false;
      enable-menu-button-arrow = false;
      gnome-dash-show-applications = true;
      hot-corners = "Disabled";
      menu-button-appearance = "Icon";
      menu-button-disable-rounded-corners = false;
      menu-button-icon = "Custom_Icon";
      menu-hotkey = "Super_L";
      menu-lyout = "Default";
      multi-monitor = true;
      override-hot-corners = true;
      position-in-panel = "Left";
      show-activities-button = false;
    };
    "org/gnome/shell/extensions/blur-my-shell" = {
      brightness = 0.6;
      dash-opacity = 0.12;
      sigma = 30;
    };
    "org/gnome/shell/extensions/dash-to-panel" = {
      appicon-margin = 2;
      appicon-padding = 6;
      dot-color-1 = sys.nzbr.theme.accentColor;
      dot-color-2 = sys.nzbr.theme.accentColor;
      dot-color-3 = sys.nzbr.theme.accentColor;
      dot-color-4 = sys.nzbr.theme.accentColor;
      dot-color-dominant = false;
      dot-color-override = true;
      dot-position = "TOP";
      dot-size = 2;
      dot-style-focused = "METRO";
      dot-style-unfocused = "METRO";
      focus-highlight-dominant = false;
      group-apps = false;
      group-apps-label-font-size = 14;
      group-apps-label-font-weight = "normal";
      group-apps-underline-unfocused = true;
      group-apps-use-launchers = false;
      hide-overview-on-startup = true;
      hot-keys = true;
      hotkeys-overlay-combo = "TEMPORARILY";
      isolate-monitors = true;
      leftbox-padding = -1;
      middle-click-action = "LAUNCH";
      panel-anchors = builtins.toJSON { "0" = "MIDDLE"; };
      panel-element-positions = builtins.toJSON {
        "0" = [
          { element = "showAppsButton"; visible = false; position = "stackedTL"; }
          { element = "activitiesButton"; visible = false; position = "stackedTL"; }
          { element = "leftBox"; visible = true; position = "stackedTL"; }
          { element = "taskbar"; visible = true; position = "stackedTL"; }
          { element = "centerBox"; visible = true; position = "stackedBR"; }
          { element = "dateMenu"; visible = true; position = "stackedBR"; }
          { element = "rightBox"; visible = true; position = "stackedBR"; }
          { element = "systemMenu"; visible = true; position = "stackedBR"; }
          { element = "desktopButton"; visible = false; position = "stackedBR"; }
        ];
      };
      panel-lengths = builtins.toJSON { "0" = 100; };
      panel-positions = builtins.toJSON { "0" = "TOP"; };
      panel-sizes = builtins.toJSON { "0" = 32; };
      scroll-panel-action = "NOTHING";
      secondarymenu-contains-showdetails = false;
      shift-click-action = "LAUNCH";
      shift-middle-click-action = "LAUNCH";
      show-appmenu = false;
      show-apps-icon-file = "";
      statuc-icon-padding = -1;
      trans-dynamic-anim-target = 0.5;
      trans-dynamic-anim-time = 500;
      trans-dynamic-behavior = "MAXIMIZED_WINDOWS";
      trans-panel-opacity = 0;
      trans-use-custom-opacity = true;
      trans-use-dynamic-opacity = true;
      tray-padding = 2;
      window-preview-title-position = "TOP";
    };
    "org/gnome/shell/extensions/trayIconsReloaded" = {
      icon-margin-horizontal = 2;
      icon-padding-horizontal = 2;
      icon-size = 20;
      icons-limit = 4;
      position-weight = 0;
      tray-margin-left = 0;
      tray-position = "right";
    };
    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };
  };
}
