{ config, lib, pkgs, modulesPath, root, ... }:
{
  options = with lib; {
    nzbr.wgIp = mkOption {
      default = "";
      type = types.str;
    };
  };

  config = {
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
