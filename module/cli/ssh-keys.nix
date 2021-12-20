{ config, lib, inputs, system, ... }:
with builtins; with lib; {
  config =
    (
      mkIf (config.nzbr.assets ? "ssh/id_ed25519") {
        age.secrets."ssh/id_ed25519" = {
          owner = config.nzbr.user;
          mode = "0600";
        };

        environment.extraInit =
          let
            id = config.nzbr.assets."ssh/id_ed25519";
            id_pub = config.nzbr.assets."ssh/id_ed25519.pub";
          in
          ''
            mkdir -p ~/.ssh
            install -m0600 ${id} ~/.ssh/id_ed25519
            install -m0600 ${id_pub} ~/.ssh/id_ed25519.pub
          '';
      }
    ) // (
      mkIf (config.nzbr.flake.root != null) (
        let
          root = config.nzbr.flake.root;
        in
        {
          services.openssh.knownHosts = lib.listToAttrs
            (map
              (hostname:
                lib.nameValuePair
                  hostname
                  {
                    hostNames = filter (x: x != "") ([
                      hostname
                      "${hostname}.nzbr.de"
                      "${hostname}4.nzbr.de"
                      "${hostname}6.nzbr.de"
                      "${hostname}.nzbr.github.beta.tailscale.net"
                    ]);
                    publicKeyFile = "${root}/host-key/${hostname}/ssh_host_ed25519_key.pub";
                  }
              )
              (
                lib.mapAttrsToList
                  (name: _: name)
                  (readDir "${root}/host-key")
              )
            );
        }
      )
    );
}
