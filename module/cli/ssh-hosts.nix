{ config, pkgs, lib, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  services.openssh.knownHosts = mkIf (root != null) (
    lib.listToAttrs
      (map
        (hostname:
          lib.nameValuePair
            hostname
            {
              hostNames = filter (x: x != "") ([
                hostname
                "${hostname}.nzbr.de"
                "${hostname}.nzbr.net"
                "${hostname}.dragon-augmented.ts.net"
              ]);
              publicKeyFile = "${root}/host-key/${hostname}/ssh_host_ed25519_key.pub";
            }
        )
        (
          lib.mapAttrsToList
            (name: _: name)
            (readDir "${root}/host-key")
        )
      )
  );
}
