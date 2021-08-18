{ config, lib, pkgs, modulesPath, ... }:
{
  services.xserver = {
    desktopManager.gnome = {
      enable = true;
      # favoriteAppsOverride = ''
      #   [org.gnome.shell]
      #   favorite-apps=[ 'vivalid-stable.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'code.desktop', 'idea-ultimate.desktop', 'gitkraken.desktop', 'insomnia.desktop', 'timeular.desktop', 'discord.desktop', 'spotify.desktop' ]
      # '';
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = lib.mkDefault true;
      };
      autoLogin = {
        enable = true;
        user = "nzbr";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gnome.dconf-editor
    # gnome.gnome-boxes
    gnome.gnome-tweak-tool
    gnome.seahorse

    local.gnome-shell-extension-pop-shell
  ] ++ (with pkgs.gnomeExtensions; [
    arcmenu
    audio-switcher-40
    blur-my-shell
    caffeine
    dash-to-panel
    gsconnect
    system-action-hibernate
    syncthing-icon
    tray-icons-reloaded
    tweaks-in-system-menu
  ]);

  programs.gnupg.agent.pinentryFlavor = "gnome3";

  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ gnome.dconf ];

  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  nixpkgs.overlays = [
    (self: super: {
      gnome = super.gnome.overrideScope' (self': super': {
        # gnome-shell = super.legacy.gnome3.gnome-shell;
        gnome-terminal = super.gnome.gnome-terminal.overrideAttrs (oldAttrs: rec {
          patches =
            let
              repo = builtins.fetchGit {
                url = "https://aur.archlinux.org/gnome-terminal-transparency.git";
                rev = "b319fb2fa68d7aaff8361cbbca79b23c4e2b29c9";
              };
              transparencyPatch = repo + "/transparency.patch";
            in
            [ transparencyPatch ];
        });
      });
    })
  ];
}
