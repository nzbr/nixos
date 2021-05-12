{ config, lib, pkgs, modulesPath, ... }:
{
  programs.gnupg.agent = {
    enable = true;
    enableBrowserSocket = true;
  };

  services.pcscd.enable = true;
}
