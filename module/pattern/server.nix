{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.pattern.server.enable = mkEnableOption "Server Pattern";

  config = mkIf config.nzbr.pattern.server.enable {
    nzbr.boot.remoteUnlock.enable = true;

    virtualisation = {
      oci-containers.backend = "docker";
    };

    services.eternal-terminal.enable = true;
    networking.firewall.allowedTCPPorts = [ config.services.eternal-terminal.port ];

    nix.gc.automatic = true;

    powerManagement.cpuFreqGovernor = "conservative";
  };
}
