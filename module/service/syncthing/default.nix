{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.syncthing = with types; {
    enable = mkEnableOption "syncthing";
  };

  config =
    let
      cfg = config.nzbr.service.syncthing;
    in
    mkIf cfg.enable (
      let
        host = config.networking.hostName;
        cert = config.nzbr.assets."syncthing/cert.pem";
        key = config.nzbr.assets."syncthing/key.pem";
      in
      (
        {
          services.syncthing = {
            enable = true;
            systemService = true;
            user = config.nzbr.user;
            group = "users";
            openDefaultPorts = true;
            dataDir = lib.mkDefault "/home/nzbr";
            declarative =
              let
                baseDir = (lib.removeSuffix "/" config.services.syncthing.dataDir) + "/";
              in
              {
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

                  hurricane.id = "RNHGREZ-WXBCXDW-KLJYXSB-I5RIE2P-FZIPGRV-44SFZAS-OPVLV4B-TRL4LA2";
                  landslide.id = "Q67E6XX-AQTLKAS-2SPVS7T-OUUPVXZ-UX632XY-DN7H2AZ-Y3N2CFJ-5EGDVAB";
                  meteor.id = "7RPEIWJ-QQDVCWD-M46KH3U-237GDWG-ZL6EEF2-WPZVAF2-7L5JRX2-HHHKKAB";

                  hurricane-win.id = "OJZKKKY-KG7PO72-VOJGPMU-X3Q6GRZ-HHA75HN-NGIGMRV-WZYPO5F-6PKEHAB";
                  earthquake-macos.id = "QCCLSA4-AFZQSHS-D4DQ2F6-VCPWNTQ-MOQSJY2-HUA5PSA-J3FTLTH-XXJAWAW";
                  uli.id = "ZOTIOGW-NRF4IWB-BXJGBLB-QGZLA6A-NEOX3CV-5DK5O2V-6PFKBXH-VK4F3AK";
                };
                folders =
                  lib.mapAttrs' (n: v: lib.nameValuePair n (v // { path = (baseDir + n); })) (# Set the path
                    lib.filterAttrs (n: v: lib.any (it: it == host) v.devices) {
                      # Only add folders that should be synced with the current host
                      Projekte = {
                        id = "projekte";
                        label = "Projekte";
                        devices = [ "earthquake" "hurricane-win" "landslide" "meteor" ];
                      };
                      devsaur = {
                        id = "devsaur";
                        label = "devsaur";
                        devices = [ "earthquake" "hurricane" "hurricane-win" "landslide" "meteor" "earthquake-macos" ];
                      };
                      Uni = {
                        id = "uni";
                        label = "Uni";
                        devices = [ "earthquake" "hurricane" "meteor" ];
                      };
                      ".local/share/fonts/sync" = {
                        id = "fonts";
                        label = "Fonts";
                        devices = [ "hurricane" "landslide" "meteor" ]; # TODO: earthquake
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
      )
    );
}
