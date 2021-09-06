{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options = with types; {
    nzbr.mullvad = mkEnableOption "Enables the mullvad desktop client";
  };

  config = mkIf config.nzbr.mullvad {
    services.mullvad-vpn.enable = true;
    environment.systemPackages = with pkgs; [
      mullvad-vpn
    ];
  };
}
