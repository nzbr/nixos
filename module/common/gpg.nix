{ config, lib, pkgs, modulesPath, ... }:
{
  programs.gnupg.agent = {
    enable = true;
    enableBrowserSocket = true;
    pinentryFlavor = lib.mkDefault "curses";
  };

  services.pcscd.enable = true;
}
