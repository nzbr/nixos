{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.service.ssh = with types; {
    enable = mkEnableOption "OpenSSH Server";

    authorizedSystems = mkOption {
      description = "Name of hosts whose SSH keys should be added to the authorized_keys file";
      type = listOf str;
      default = [ ];
    };
  };

  config =
    let
      cfg = config.nzbr.service.ssh;
    in
    mkIf cfg.enable {
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "yes";
          X11Forwarding = true;
        };
        hostKeys = [
          {
            type = "ed25519";
            path = "/etc/ssh/ssh_host_ed25519_key";
          }
          {
            type = "rsa";
            path = "/etc/ssh/ssh_host_rsa_key";
          }
        ];
      };

      users.users =
        let
          keys = map
            (host: (readFile' config.nzbr.foreignAssets.${host}."ssh/id_ed25519.pub"))
            (cfg.authorizedSystems);
        in
        {
          root.openssh.authorizedKeys.keys = keys;
          ${config.nzbr.user}.openssh.authorizedKeys.keys = keys;
        };
    };

}
