# See also: https://tailscale.com/blog/nixos-minecraft/

{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.service.tailscale = with types; {
    enable = mkEnableOption "Tailscale";
  };

  config =
    let
      cfg = config.nzbr.service.tailscale;
    in
    mkIf cfg.enable {

      services.tailscale = {
        enable = true;
        package = pkgs.unstable.tailscale;
      };

      environment.systemPackages = [
        config.services.tailscale.package
      ];

      nzbr.home.autostart = mkIf config.nzbr.pattern.desktop.enable [
        "${pkgs.local.tailscale-ui}/bin/tailscale-ui"
      ];

      # create a oneshot job to authenticate to Tailscale
      systemd.services.tailscale-autoconnect = rec {
        description = "Automatic connection to Tailscale";

        # make sure tailscale is running before trying to connect to tailscale
        after = [ "network-pre.target" "tailscale.service" ];
        wants = after;
        wantedBy = [ "multi-user.target" ];

        # set this service as a oneshot job
        serviceConfig.Type = "oneshot";

        # have the job run this shell script
        script =
          let
            tailscale = config.services.tailscale.package;
          in
          ''
            # wait for tailscaled to settle
            sleep 2

            # check if we are already authenticated to tailscale
            status="$(${tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
            if ! [ $status = "Running" ]; then # if so, then do nothing
              # authenticate with tailscale
              ${tailscale}/bin/tailscale up -authkey ''$(cat ${config.nzbr.assets."tskey"})
            fi
          '';
      };

      networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };
    };
}
