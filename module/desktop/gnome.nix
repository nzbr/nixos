{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.desktop.gnome = with types; {
    enable = mkEnableOption "GNOME Desktop Environment";
  };

  config = mkIf config.nzbr.desktop.gnome.enable {
    nzbr.desktop.theme.enable = true;

    services.xserver = {
      desktopManager.gnome = {
        enable = true;
      };
      displayManager = {
        gdm = {
          enable = true;
          wayland = lib.mkDefault true;
        };
        autoLogin = {
          enable = true;
          user = config.nzbr.user;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      gnome.dconf-editor
      # gnome.gnome-boxes
      gnome.gnome-tweaks
      gnome.seahorse

      local.gnome-shell-extension-pop-shell
    ] ++ (
      let
        extensions =
          pkgs.gnome41Extensions
            // { "arcmenu@arcmenu.com" = pkgs.unstable.gnomeExtensions.arcmenu; }; # other arcmenu package is broken for some reason
      in
      map
        (ext: extensions.${ext})
        config.nzbr.home.config.dconf.settings."org/gnome/shell".enabled-extensions
    );

    programs.dconf.enable = true;
    services.dbus.packages = with pkgs; [ dconf ];

    services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

    nixpkgs.overlays = [
      (self: super: {
        gnome = super.gnome.overrideScope' (self': super': {
          # gnome-terminal = super'.gnome-terminal.overrideAttrs (oldAttrs: rec {
          #   patches =
          #     let
          #       repo = builtins.fetchGit {
          #         url = "https://aur.archlinux.org/gnome-terminal-transparency.git";
          #         rev = "7dd7cd2471e42af8130cda7905b2b2c2a334ac4b";
          #       };
          #       transparencyPatch = repo + "/transparency.patch";
          #     in
          #     [ transparencyPatch ];
          # });
        });
      })
    ];

    age.secrets = lib.mkIf config.nzbr.agenix.enable {
      "Starfield2.png".mode = "0644";
    };

    nzbr.home.config =
      let
        displays = [ "0" "1" ];
        forEachDisplay = value:
          builtins.toJSON (
            builtins.listToAttrs (
              map
                (num: lib.nameValuePair num value)
                displays
            )
          );
      in
      {
        dconf.settings = lib.mkIf config.services.xserver.desktopManager.gnome.enable {
          "org/gnome/desktop/background" = {
            picture-options = "zoom";
            picture-uri = "file://${config.nzbr.assets."Starfield2.png"}";
            primary-color = "#000000";
            secondary-color = "#ffffff";
            show-desktop-icons = false;
          };
          "org/gnome/desktop/interface" = {
            gtk-theme = "Pop-dark";
            icon-theme = "Papirus-Dark";
          };
          "org/gnome/desktop/screensaver" = {
            lock-delay = 0;
            lock-enabled = true;
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
            disable-user-extensions = false;
            enabled-extensions = [
              "appindicatorsupport@rgcjonas.gmail.com"
              "arcmenu@arcmenu.com"
              # "audio-switcher@albertomosconi"
              "bluetooth-quick-connect@bjarosze.gmail.com"
              "caffeine@patapon.info"
              "dash-to-panel@jderose9.github.com"
              "drive-menu@gnome-shell-extensions.gcampax.github.com"
              "expandable-notifications@kaan.g.inam.org"
              "gsconnect@andyholmes.github.io"
              # "hibernate@dafne.rocks"
              "hibernate-status@dromi" # Placeholder for the above extension
              "notification-position@drugo.dev"
              # "remmina-search-provider@alexmurray.github.com"
              "spotify-artwork-fixer@wjt.me.uk"
              # "tweaks-system-menu@extensions.gnome-shell.fifi.org"
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              # "blur-my-shell@aunetx"
              # "trayIconsReloaded@selfmade.pl"
            ];
            favorite-apps = [
              "firefox.desktop"
              "org.gnome.Nautilus.desktop"
              "org.gnome.Terminal.desktop"
              "code.desktop"
              "idea-ultimate.desktop"
              "gitkraken.desktop"
              "timeular.desktop"
              # "discord.desktop"
              # "spotify.desktop"
            ];
            welcome-dialog-last-shown-version = pkgs.gnome3.gnome-shell.version;
          };
          "org/gnome/shell/extensions/arcmenu" = {
            arc-menu-icon = 7;
            arc-menu-placement = "DTP";
            available-placement = [ false true false ];
            # custom-menu-button-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
            custom-menu-button-icon = "${config.nzbr.assets."Start.png"}";
            custom-menu-button-icon-size = 24;
            custom-menu-button-text = "";
            default-menu-view = "Frequent_Apps";
            distro-icon = 1;
            enable-custom-arc-menu = false;
            enable-menu-button-arrow = false;
            gnome-dash-show-applications = true;
            hot-corners = "Disabled";
            menu-button-appearance = "Icon";
            menu-button-disable-rounded-corners = true;
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
            dot-color-1 = config.nzbr.desktop.theme.accentColor;
            dot-color-2 = config.nzbr.desktop.theme.accentColor;
            dot-color-3 = config.nzbr.desktop.theme.accentColor;
            dot-color-4 = config.nzbr.desktop.theme.accentColor;
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
            panel-anchors = forEachDisplay "MIDDLE";
            panel-element-positions = forEachDisplay [
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
            panel-lengths = forEachDisplay 100;
            panel-positions = forEachDisplay "TOP";
            panel-sizes = forEachDisplay 32;
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
      };
  };
}
