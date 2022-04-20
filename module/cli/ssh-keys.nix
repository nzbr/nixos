{ config, lib, inputs, system, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  config =
    mkIf (root != null && (hasAttr "ssh" (readDir root))) {
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
    };
}
