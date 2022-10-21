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
          } // (
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
                  addresses = [ "quic://10.0.1.2:22000" "quic://earthquake.nzbr.de" "quic://100.71.200.40:22000" "dynamic" ];
                  id = "JDXIQUR-4FUQQK6-CZFNZTA-NCWBFEU-HCZFDW5-E7X2KKX-BIQWZZZ-2B42XQF";
                  introducer = true;
                };

                hurricane.id = "RNHGREZ-WXBCXDW-KLJYXSB-I5RIE2P-FZIPGRV-44SFZAS-OPVLV4B-TRL4LA2";
                landslide.id = "Q67E6XX-AQTLKAS-2SPVS7T-OUUPVXZ-UX632XY-DN7H2AZ-Y3N2CFJ-5EGDVAB";
                meteor.id = "7RPEIWJ-QQDVCWD-M46KH3U-237GDWG-ZL6EEF2-WPZVAF2-7L5JRX2-HHHKKAB";

                comet.id = "S33W76X-E3KIOOT-GDAAKNY-LLXR2CA-KQUIBNA-TC7R7TL-SJASVY3-UCFBCQM";
                earthquake-macos.id = "QCCLSA4-AFZQSHS-D4DQ2F6-VCPWNTQ-MOQSJY2-HUA5PSA-J3FTLTH-XXJAWAW";
                hurricane-win.id = "ORTVEOF-CUZIQQI-HXPIVQW-FSS4B3F-JVSDTQV-GBB233Q-ESXFKKW-GWNPNQN";
                magnetar.id = "KGUM5PX-JMVXHTL-LOUH3NP-LTA5JGV-TBS2MFY-4V2K2JL-PJHNEHV-DRCDIAJ";
                pulsar-win.id = "RXTBIQ6-C6SQFBC-DO2MIUA-FL7RUW2-PN6ILZC-4QMIIZX-UYP5RB7-FC3H5QK";
                uli.id = "ZOTIOGW-NRF4IWB-BXJGBLB-QGZLA6A-NEOX3CV-5DK5O2V-6PFKBXH-VK4F3AK";
              };
              folders =
                lib.mapAttrs' (n: v: lib.nameValuePair n (v // { path = (baseDir + n); })) (# Set the path
                  # Only add folders that should be synced with the current host
                  lib.filterAttrs (n: v: lib.any (it: it == host) v.devices) (import ./folders.conf));
            }
          );
        }
      )
    );
}
