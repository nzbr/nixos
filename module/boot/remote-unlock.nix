{ config, lib, pkgs, modulesPath, ... }:
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
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
          hostKeys = [
            "/etc/ssh/ssh_host_ed25519_key"
            # (builtins.unsafeDiscardStringContext "${root}/host/${config.networking.hostName}/ssh/ssh_host_ed25519_key")
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
            # Ask for luks password when logging in via SSH
            ${luks}
            ${zfs}

            # Setup network
            ${ipconfig}

            echo ""
            echo '######################'
            echo '# NETWORK INTERFACES #'
            echo '######################'
            echo ""
            ip a
            echo ""
          '';
      };
    };
  };
}
