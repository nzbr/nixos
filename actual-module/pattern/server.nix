{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.pattern.server.enable = mkEnableOption "Server Pattern";

  config = mkIf config.nzbr.pattern.server.enable {
    nzbr.pattern.common.enable = true;
    nzbr.boot.remoteUnlock.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_hardened;
  };
}
