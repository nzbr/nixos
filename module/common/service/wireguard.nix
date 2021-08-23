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
          privateKey = (lib.fileContents "${root}/secret/${config.networking.hostName}/wireguard/private.key");
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
