{ config, lib, pkgs, modulesPath, ... }:
let
  host = config.networking.hostName;
  cert = ../../../secret + "/${host}/syncthing/cert.pem";
  key = ../../../secret + "/${host}/syncthing/key.pem";
in
{
  services.syncthing = {
    enable = true;
    systemService = true;
    user = "nzbr";
    group = "users";
    openDefaultPorts = true;
    dataDir = lib.mkDefault "/home/nzbr";
    declarative =
      let
        baseDir = (lib.removeSuffix "/" config.services.syncthing.dataDir) + "/";
      in {
        cert = "${cert}";
        key = "${key}";
        overrideDevices = true;
        overrideFolders = true;
        devices = {
          earthquake = {
            addresses = [ "quic://earthquake.nzbr.de:22000" "quic://10.42.0.2:22000" ];
            id = "JDXIQUR-4FUQQK6-CZFNZTA-NCWBFEU-HCZFDW5-E7X2KKX-BIQWZZZ-2B42XQF";
            introducer = true;
          };
          hurricane = {
            id = "OJZKKKY-KG7PO72-VOJGPMU-X3Q6GRZ-HHA75HN-NGIGMRV-WZYPO5F-6PKEHAB";
          };
          landslide = {
            id = "Q67E6XX-AQTLKAS-2SPVS7T-OUUPVXZ-UX632XY-DN7H2AZ-Y3N2CFJ-5EGDVAB";
          };
          meteor = {
            id = "7RPEIWJ-QQDVCWD-M46KH3U-237GDWG-ZL6EEF2-WPZVAF2-7L5JRX2-HHHKKAB";
          };

          uli = {
            id = "ZOTIOGW-NRF4IWB-BXJGBLB-QGZLA6A-NEOX3CV-5DK5O2V-6PFKBXH-VK4F3AK";
          };
        };
        folders =
          lib.mapAttrs' (n: v: lib.nameValuePair n (v // { path = (baseDir + n);})) ( # Set the path
          lib.filterAttrs (n: v: lib.any(it: it == host) v.devices) { # Only add folders that should be synced with the current host
            Projekte = {
              id = "projekte";
              label = "Projekte";
              devices = [ "earthquake" "hurricane" "landslide" "meteor" ];
            };
            devsaur = {
              id = "devsaur";
              label = "devsaur";
              devices = [ "earthquake" "hurricane" "landslide" "meteor" ];
            };
            mp3 = {
              id = "mp3";
              label = "MP3";
              devices = [ "earhquake" "uli" ];
            };
          });
      };
  };
}
