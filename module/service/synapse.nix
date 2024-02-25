{ config, lib, inputs, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.service.synapse = with types; {
    enable = mkEnableOption "Synapse Matrix Server";
  };

  config =
    let
      cfg = config.nzbr.service.synapse;
    in
    mkIf cfg.enable {

      age.secrets."synapse.yaml".owner = "matrix-synapse";

      services.matrix-synapse = {
        enable = true;
        dataDir = "/storage/synapse";
        withJemalloc = true;
        settings = {
          public_baseurl = "https://nzbr.de:8448/";
          enable_registration = false;
          server_name = "nzbr.de";
          max_upload_size = "50M";
          database = {
            name = "psycopg2";
            user = "synapse";
            args = {
              host = "firestorm.dragon-augmented.ts.net";
            };
          };
          trusted_key_servers = [
            {
              server_name = "matrix.org";
              verify_keys = {
                "ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
              };
            }
          ];
          listeners = [
            {
              bind_addresses = [
                config.nzbr.nodeIp
              ];
              port = 28448;
              resources = [
                {
                  compress = true;
                  names = [
                    "client"
                  ];
                }
                {
                  compress = false;
                  names = [
                    "federation"
                  ];
                }
              ];
              tls = false;
              type = "http";
              x_forwarded = true;
            }
          ];
          app_service_config_files = [
          ];
        };
        extraConfigFiles = [
          config.nzbr.assets."synapse.yaml"

          (pkgs.writeText "config.yaml" (toJSON {
            suppress_key_server_warning = true;
          }))
        ];
        sliding-sync = {
          enable = true;
          createDatabase = false;
          environmentFile = config.nzbr.assets."matrix-sliding-sync.env";
          settings = {
            SYNCV3_SERVER = "https://matrix.nzbr.de";
            SYNCV3_BINDADDR = ":8009";
          };
        };
      };

    };

}
