{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.network.wireguard = with lib; {
    enable = mkEnableOption "wireguard VPN";
    ip = mkOption {
      default = "";
      type = types.str;
    };
  };

  config =
    let
      cfg = config.nzbr.network.wireguard;
    in
    mkIf cfg.enable {
      networking = {
        wireguard = {
          enable = true;
          interfaces.wg0 = {
            privateKeyFile = config.nzbr.assets."wireguard/private.key";
            listenPort = lib.mkDefault 51820;
          };
        };

        firewall = {
          allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];
          trustedInterfaces = [ "wg0" ];
        };
      };
    };
}
