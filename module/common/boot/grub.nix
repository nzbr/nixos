{ config, lib, pkgs, modulesPath, ... }:
{
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    enableCryptodisk = true;
    extraConfig = ''
      set gfxpayload=keep
    '';
  };
}
