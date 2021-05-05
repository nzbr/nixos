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
    gnome3.gnome-tweak-tool
    gnome3.seahorse
  ];

  programs.gnupg.agent.pinentryFlavor = "gnome3";
}
