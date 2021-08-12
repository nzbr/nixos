{ config, lib, pkgs, ... }:
let
  secrets = ../../secret + "/${config.sys.networking.hostName}/ssh";
  id = "${secrets}/id_ed25519";
  id_pub = "${secrets}/id_ed25519.pub";
in
{
  home.file = {
    copy-ssh-keys-hook = with builtins; lib.mkIf (hasAttr "id_ed25519" (readDir secrets)) {
      target = ".config/shell-hooks/copy-ssh-keys.pre";
      text = ''
        mkdir -p ~/.ssh
        install -m0600 ${id} ~/.ssh/id_ed25519
        install -m0600 ${id_pub} ~/.ssh/id_ed25519.pub
      '';
    };
  };
}
