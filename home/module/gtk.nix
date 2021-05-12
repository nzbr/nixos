{ config, lib, pkgs, ... }:
{
  gtk = lib.mkIf config.services.xserver.enable {
    theme = {
      package = pkgs.pop-gtk-theme;
      name = "Pop-dark";
    };
  };
}
