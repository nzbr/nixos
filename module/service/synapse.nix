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
        server_name = "nzbr.de";
        public_baseurl = "https://nzbr.de:8448/";
        servers = {
          "matrix.org" = {
            "ed25519:auto" = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
          };
        };
        dataDir = "/storage/synapse";
        enable_registration = false;
        listeners = [
          {
            bind_address = "";
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
        database_type = "psycopg2";
        database_user = "synapse";
        database_args = {
          host = "storm.nzbr.github.beta.tailscale.net";
        };
        withJemalloc = true;
        max_upload_size = "50M";
        extraConfigFiles = [
          config.nzbr.assets."synapse.yaml"

          (pkgs.writeText "config.yaml" (toJSON {
            suppress_key_server_warning = true;
          }))
        ];
        app_service_config_files = [
        ];
      };

    };

}
