{ config, lib, pkgs, ... }:
with builtins; with lib;
let
  cfg = config.nzbr.program.mullvad;
in
{
  options.nzbr.program.mullvad = with types; {
    enable = mkEnableOption "Enables the mullvad desktop client";
  };

  config = mkIf cfg.enable {
    services.mullvad-vpn.enable = true;
    environment.systemPackages = with pkgs; [
      mullvad-vpn
    ];
  };
}
