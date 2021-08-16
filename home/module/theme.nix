{ config, lib, pkgs, ... }:
{
  gtk = {
    iconTheme = {
      # package = pkgs.local.papirus-icon-theme-mod;
      name = "Papirus-dark";
    };
    theme = {
      # package = pkgs.pop-gtk-theme;
      name = "Pop-dark";
    };
  };
}
