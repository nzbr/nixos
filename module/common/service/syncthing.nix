{ config, lib, pkgs, modulesPath, ... }:
let
  cert = ../../../secret + "/${config.networking.hostName}/syncthing/cert.pem";
  key = ../../../secret + "/${config.networking.hostName}/syncthing/key.pem";
in
{
  services.syncthing = {
    enable = true;
    systemService = true;
    user = "nzbr";
    group = "users";
    openDefaultPorts = true;
    dataDir = lib.mkDefault "/home/nzbr";
    declarative = {
      cert = "${cert}";
      key = "${key}";
      overrideDevices = true;
      overrideFolders = true;
      devices = {
        # earthquake = {
        #   addresses = [ "quic://earthquake.nzbr.de:22000" "quic://10.42.0.2:22000" ];
        #   id = "";
        #   introducer = true;
        # };
        hurricane = {
          id = "OJZKKKY-KG7PO72-VOJGPMU-X3Q6GRZ-HHA75HN-NGIGMRV-WZYPO5F-6PKEHAB";
        };
        landslide = {
          id = "Q67E6XX-AQTLKAS-2SPVS7T-OUUPVXZ-UX632XY-DN7H2AZ-Y3N2CFJ-5EGDVAB";
        };
        meteor = {
          id = "7RPEIWJ-QQDVCWD-M46KH3U-237GDWG-ZL6EEF2-WPZVAF2-7L5JRX2-HHHKKAB";
        };
      };
      folders = {
        "Projekte" = {
          id = "projekte";
          label = "Projekte";
          devices = [ "hurricane" "landslide" "meteor" ];
        };
        "devsaur" = {
          id = "devsaur";
          label = "devsaur";
          devices = [ "hurricane" "landslide" "meteor" ];
        };
      };
    };
  };
}
