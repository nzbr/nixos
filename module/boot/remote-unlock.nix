{ config, lib, pkgs, modulesPath, inputs, ... }:
with builtins; with lib;
let
  cfg = config.nzbr.boot.remoteUnlock;
in
{
  options.nzbr.boot.remoteUnlock = with types; {
    enable = mkEnableOption "SSH Remote unlock";
    luks = mkOption {
      default = true;
      type = bool;
    };
    zfs = mkOption {
      default = [ ];
      type = listOf str;
    };
  };

  config = mkIf cfg.enable {
    boot.initrd = {
      secrets = mkIf config.nzbr.service.tailscale.enable {
        "/var/lib/tailscale/tailscaled.state" = "/var/lib/tailscale/tailscaled.state";
      };
      kernelModules = mkIf config.nzbr.service.tailscale.enable [ "tun" "nf_tables" "nft_compat" ];
      extraFiles = {
        "/etc/ssl/certs/ca-certificates.crt".source = pkgs.runCommand "ca-bundle.crt" { } "cp ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out";
      };
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
          hostKeys = [
            "/etc/ssh/ssh_host_ed25519_key"
          ];
        };
        postCommands =
          let
            ipconfig = with builtins; with lib;
              concatStringsSep "\n" (
                flatten (
                  mapAttrsToList
                    (
                      name: value:
                        flatten
                          (
                            map
                              (ip: "ip addr add ${ip.address}/${toString ip.prefixLength} dev ${name}")
                              value.ipv4.addresses
                          )
                        ++ [ "ip link set ${name} up" ]
                    )
                    (config.networking.interfaces)
                )
              );
            luks =
              if cfg.luks then
                "echo 'cryptsetup-askpass' >> /root/.profile"
              else
                "";
            zfs = lib.concatStringsSep "\n"
              (
                builtins.map
                  (vol: "echo 'zfs load-key ${vol} && killall zfs' >> /root/.profile")
                  cfg.zfs
              );
          in
          ''
            # Print console log when logging in via SSH
            echo "dmesg" >> /root/.profile

            # Ask for luks password when logging in via SSH
            ${luks}
            ${zfs}

            # Set hostname
            hostname ${config.networking.hostName}

            # Setup network
            ${ipconfig}

            ${optionalString (config.nzbr.service.tailscale.enable) ''
              export PATH="$PATH":${pkgs.iptables}/bin
              # Start tailscaled
              ${config.services.tailscale.package}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=${toString config.services.tailscale.port} &
              sleep 3s
            ''}

            echo ""
            echo '######################'
            echo '# NETWORK INTERFACES #'
            echo '######################'
            echo ""
            ip a
            echo ""

            {
              export PATH="$PATH":${pkgs.openssl}/bin
              KEY=$(${pkgs.rage}/bin/rage -d -i /etc/ssh/ssh_host_ed25519_key ${inputs.self}/asset/pushbulletKey.age)
              ${pkgs.curl}/bin/curl --silent -u "$KEY": -X POST https://api.pushbullet.com/v2/pushes --header 'Content-Type: application/json' --data-binary '{"type": "note", "title": "Remote Unlock", "body": "${config.networking.hostName} requests a password"}' >/dev/null
            } || true
          '';
      };
      postMountCommands = ''
        pkill -x tailscaled || true
      '';
    };
  };
}
