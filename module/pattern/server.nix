{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.pattern.server.enable = mkEnableOption "Server Pattern";

  config = mkIf config.nzbr.pattern.server.enable {
    nzbr.boot.remoteUnlock.enable = true;

    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    virtualisation = {
      docker.enable = true;
      oci-containers.backend = "docker";
    };

    nix.gc.automatic = true;
  };
}
