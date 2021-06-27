{ config, lib, pkgs, modulesPath, ... }:
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
          privateKey = (lib.fileContents (../../../secret + "/${config.networking.hostName}/wireguard/private.key"));
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
