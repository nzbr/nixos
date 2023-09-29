{ config, lib, pkgs, modulesPath, inputs, ... }:
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
              devices =
                let
                  hostsDir = "${inputs.self}/host";
                in
                (recursiveUpdate
                  (
                    foldl recursiveUpdate { }
                      (
                        mapAttrsToList
                          (n: v:
                            let
                              cert = "${hostsDir}/${n}/syncthing/cert.pem";
                              encoder = pkgs.stdenv.mkDerivation {
                                name = "encoder";
                                buildInputs = [
                                  (pkgs.python3.withPackages
                                    (pypi: [
                                      pypi.python-stdnum
                                    ])
                                  )
                                ];
                                buildCommand = ''
                                  cp ${inputs.syncthing-key-generator}/tools/encoded-id.py $out
                                  patchShebangs --host $out
                                '';
                              };
                              id = (readFile (pkgs.runCommand "id" { nativeBuildInputs = [ pkgs.openssl ]; } ''
                                openssl x509 -in ${cert} -outform der | openssl dgst -binary -sha256 | base32 | ${encoder} | tr -d '\n' > $out
                              ''));
                            in
                            if pathExists cert
                            then {
                              ${n} = {
                                inherit id;
                              };
                            }
                            else { }
                          )
                          (readDir hostsDir)
                      )
                  )
                  {
                    earthquake = {
                      addresses = [ "quic://10.0.1.2:22000" "quic://earthquake.nzbr.de" "quic://100.71.200.40:22000" "dynamic" ];
                      introducer = true;
                    };

                    macos-vm.id = "24K2KDG-I5SD2KE-L3BR5C2-3EM4MTF-ITUVGLX-5OJCBXJ-AQDHMEZ-MX47KQW";
                    hurricane-win.id = "ORTVEOF-CUZIQQI-HXPIVQW-FSS4B3F-JVSDTQV-GBB233Q-ESXFKKW-GWNPNQN";
                    magnetar.id = "KGUM5PX-JMVXHTL-LOUH3NP-LTA5JGV-TBS2MFY-4V2K2JL-PJHNEHV-DRCDIAJ";
                    pulsar-win.id = "RXTBIQ6-C6SQFBC-DO2MIUA-FL7RUW2-PN6ILZC-4QMIIZX-UYP5RB7-FC3H5QK";
                    uli.id = "ZOTIOGW-NRF4IWB-BXJGBLB-QGZLA6A-NEOX3CV-5DK5O2V-6PFKBXH-VK4F3AK";
                  }
                );
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
