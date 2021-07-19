{ config, lib, pkgs, modulesPath, ... }:
{
  services.xserver = {
    desktopManager.gnome3.enable = true;
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
    gnome3.gnome-boxes
    gnome3.gnome-tweak-tool
    gnome3.seahorse

    local.gnome-shell-extension-pop-shell

    pop-gtk-theme
    local.papirus-icon-theme-mod
   ] /* ++ (with pkgs.gnomeExtensions; [
     caffeine
     dash-to-dock
     gsconnect
   ])*/;

  programs.gnupg.agent.pinentryFlavor = "gnome3";

  programs.dconf.enable = true;
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  nixpkgs.overlays = [
    (self: super: {
      gnome3 = super.gnome3.overrideScope' (self': super': {
        gnome-terminal = super'.gnome-terminal.overrideAttrs (oldAttrs: rec {
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
