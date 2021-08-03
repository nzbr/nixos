{ config, lib, pkgs, modulesPath, ... }:
{
  services.xserver = {
    desktopManager.gnome = {
      enable = true;
      # TODO: favoriteAppsOverride
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
    gnome.gnome-boxes
    gnome.gnome-tweak-tool
    gnome.seahorse

    local.gnome-shell-extension-pop-shell
  ] /* ++ (with pkgs.gnomeExtensions; [
     caffeine
     dash-to-dock
     gsconnect
   ])*/;

  programs.gnupg.agent.pinentryFlavor = "gnome3";

  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ gnome.dconf ];

  nixpkgs.overlays = [
    (self: super: {
      gnome = super.gnome.overrideScope' (self': super': {
        gnome-shell = super.legacy.gnome3.gnome-shell;
        gnome-terminal = super.legacy.gnome3.gnome-terminal.overrideAttrs (oldAttrs: rec {
          patches =
            let
              repo = builtins.fetchGit {
                url = "https://aur.archlinux.org/gnome-terminal-transparency.git";
                rev = "3a48ec49f7aec584d505d54bbb0325d8561021a2";
              };
              transparencyPatch = repo + "/transparency.patch";
            in
            [ transparencyPatch ];
        });
      });
    })
  ];
}
