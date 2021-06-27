{ config, lib, pkgs, modulesPath, ... }:
{
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 22;
      authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      hostKeys = [
        (../../secret + "/${config.networking.hostName}/ssh/ssh_host_ed25519_key")
      ];
    };
    postCommands =
    let
      ipconfig = with builtins; with lib;
        concatStringsSep "\n" (
          flatten (
            mapAttrsToList (
              name: value:
                flatten (
                  map
                    (ip: "ip addr add ${ip.address}/${toString ip.prefixLength} dev ${name}")
                    value.ipv4.addresses
                )
                ++ [ "ip link set ${name} up" ]
            )
            (config.networking.interfaces)
        )
      );
    in ''
      # Ask for luks password when logging in via SSH
      echo 'cryptsetup-askpass' >> /root/.profile

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
}
