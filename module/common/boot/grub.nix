{ config, lib, pkgs, modulesPath, ... }:
{
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = lib.mkDefault "nodev";
    enableCryptodisk = true;
    extraConfig = ''
      set gfxpayload=keep
    '';
  };
}
