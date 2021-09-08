{ config, lib, pkgs, ... }:
with builtins; with lib;
let
  cfg = config.nzbr.mullvad;
in
{
  options = with types; {
    nzbr.mullvad.enable = mkEnableOption "Enables the mullvad desktop client";
  };

  config = mkIf cfg.enable {
    networking.firewall.checkReversePath = false;

    services.mullvad-vpn.enable = true;
    environment.systemPackages = with pkgs; [
      mullvad-vpn
    ];
  };
}
