# See also: https://tailscale.com/blog/nixos-minecraft/

{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.service.tailscale = with types; {
    enable = mkEnableOption "Tailscale";
    exit = mkBoolOpt false;
    cert = mkEnableOption "Tailscale TLS certificate";
    authkey = mkStrOpt config.nzbr.assets."tskey";
  };

  config =
    let
      cfg = config.nzbr.service.tailscale;
      tailscale = "${config.services.tailscale.package}/bin/tailscale";
    in
    mkIf cfg.enable {

      services.tailscale = {
        enable = true;
      };

      environment.systemPackages = [
        config.services.tailscale.package
      ];

      systemd = {

        services = {
          # create a oneshot job to authenticate to Tailscale
          tailscale-up = rec {
            description = "Automatic connection to Tailscale";

            # make sure tailscale is running before trying to connect to tailscale
            after = [ "network-pre.target" "tailscale.service" ];
            requires = [ "tailscaled.service" ];
            wants = after;
            wantedBy = [ "tailscale.target" ];

            # set this service as a oneshot job
            serviceConfig.Type = "oneshot";

            # have the job run this shell script
            script =
              let
                options = concatStringsSep " " (flatten [
                  (optional cfg.exit "--advertise-exit-node")
                ]);
              in
              ''
                # wait for tailscaled to settle
                sleep 2

                # check if we are already authenticated to tailscale
                status="$(${tailscale} status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
                if ! [ $status = "Running" ]; then
                  # authenticate with tailscale
                  ${tailscale} up -authkey ''$(cat ${cfg.authkey}) ${options}
                else
                  # reconfigure but don't authenticate
                  ${tailscale} up ${options}
                fi
              '';
          };

          tailscale-cert = mkIf cfg.cert rec {
            description = "Tailscale TLS certificate";

            requires = [ "tailscale-up.service" ];
            after = requires;
            wantedBy = [ "tailscale.target" ];

            serviceConfig.Type = "oneshot";
            script = ''
              mkdir -p /run/tailscale

              DOMAIN=$(${tailscale} status --json | ${pkgs.jq}/bin/jq -r '.Self.DNSName' | ${pkgs.gnused}/bin/sed 's/\.$//')
              CERT_DIR=/var/lib/tailscale/certs

              ${tailscale} cert --cert-file $CERT_DIR/.tailscale.crt --key-file $CERT_DIR/.tailscale.key $DOMAIN
              mv -f $CERT_DIR/.tailscale.crt $CERT_DIR/tailscale.crt
              mv -f $CERT_DIR/.tailscale.key $CERT_DIR/tailscale.key

              chown -R root:tailscale $CERT_DIR $CERT_DIR/..
              chmod -R 640 $CERT_DIR
              chmod g+rx $CERT_DIR $CERT_DIR/..
            '';
          };

        };

        timers.tailscale-cert-renew = mkIf cfg.cert {
          wantedBy = [ "timers.target" ];
          partOf = [ "tailscale-cert.service" ];
          timerConfig.OnCalendar = "*-*-01 06:00:00";
        };

        targets.tailscale = {
          description = "Tailscale";

          wants = [ "tailscale.service" ];
          wantedBy = [ "multi-user.target" ];
        };
      };

      users.groups.tailscale = { };

      networking.firewall = {
        checkReversePath = "loose";
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };
    };
}
