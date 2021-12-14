{ config, pkgs, lib, ... }:
with builtins; with lib; {
  options.nzbr.network.iwd = with types; {
    enable = mkEnableOption "iNet Wireless Daemon";
  };

  config =
    let
      cfg = config.nzbr.network.iwd;
    in
    mkIf cfg.enable {
      networking = {
        wireless.iwd.enable = true;
        networkmanager.wifi.backend = "iwd";
      };

      system.activationScripts.iwd = mkIf config.nzbr.agenix.enable stringAfter [ "agenix" ] ''
        mkdir -p /run/iwd
        find /run/iwd/ -type f -delete
        for net in ${config.age.secretsMountPoint}/*/iwd/*; do
          FILE="/run/iwd/$(head -n1 $net)"
          tail -n+2 $net > "$FILE"
        done
      '';

      systemd.services.iwd = {
        environment = {
          STATE_DIRECTORY = mkIf config.nzbr.agenix.enable "/run/iwd";
        };
        serviceConfig = {
          ReadWritePaths = [ "/run/iwd" ];
        };
        restartTriggers =
          mapAttrsToList
            (name: type: hashFile "sha256" "${config.nzbr.flake.assets}/iwd/${name}")
            (readDir "${config.nzbr.flake.assets}/iwd/");
      };
    };
}
