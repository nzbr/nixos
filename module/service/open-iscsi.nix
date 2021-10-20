{ config, lib, inputs, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.openIscsi.enable = mkEnableOption "Open iSCSI";

  config = mkIf config.nzbr.service.openIscsi.enable {
    environment.systemPackages = with pkgs; [
      openiscsi
    ];

    services.openiscsi = {
      enable = true;
      name = "iqn.2020-08.org.linux-iscsi.initiatorhost:${config.networking.hostName}";
      package = pkgs.openiscsi;
    };
  };
}
