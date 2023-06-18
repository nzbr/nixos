{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {

  options.nzbr.boot.grub = {
    enable = mkEnableOption "GRUB Bootloader";
  };

  config = mkIf config.nzbr.boot.grub.enable {
    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      device = lib.mkDefault "nodev";
      enableCryptodisk = true;
      extraConfig = ''
        set gfxpayload=keep
      '';
    };
  };
}
