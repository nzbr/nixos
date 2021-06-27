{ config, lib, pkgs, ... }:
let
  id = ../../secret + "/${config.networking.hostName}/ssh/id_ed25519";
  id_pub = ../../secret + "/${config.networking.hostName}/ssh/id_ed25519.pub";
in
{
  home.file = {
    copy-ssh-keys-hook = {
      target = ".config/shell-hooks/copy-ssh-keys.pre";
      text = ''
        mkdir -p ~/.ssh
        install -m0600 ${id} ~/.ssh/id_ed25519
        install -m0600 ${id_pub} ~/.ssh/id_ed25519.pub
      '';
    };
  };
}
