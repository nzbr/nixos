{ config, lib, pkgs, ... }:
{
  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file://${../../secret/common/Starfield2.png}";
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
      welcome-dialog-last-shown-version = "40.1";
    };
    "org/gnome/shell/extensions/blur-my-shell" = {
      brightness = 0.6;
      dash-opacity = 0.12;
      sigma = 30;
    };
    "org/gnome/shell/extensions/dash-to-panel" = {
      appicon-margin = 2;
      appicon-padding = 4;
      dot-color-1 = config.sys.nzbr.theme.accentColor;
      dot-color-2 = config.sys.nzbr.theme.accentColor;
      dot-color-3 = config.sys.nzbr.theme.accentColor;
      dot-color-4 = config.sys.nzbr.theme.accentColor;
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
          { element = "showAppsButton"; visible = true; position = "stackedTL"; }
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
    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };
  };
}
