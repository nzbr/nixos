{ config, lib, pkgs, sys, root, ... }:
{
  home.file = {
    copy-ssh-keys-hook = with builtins; lib.mkIf (hasAttr "ssh/id_ed25519" sys.nzbr.assets) (
      let
        id = sys.nzbr.assets."ssh/id_ed25519";
        id_pub = sys.nzbr.assets."ssh/id_ed25519.pub";
      in
      {
        target = ".config/shell-hooks/copy-ssh-keys.pre";
        text = ''
          mkdir -p ~/.ssh
          install -m0600 ${id} ~/.ssh/id_ed25519
          install -m0600 ${id_pub} ~/.ssh/id_ed25519.pub
        '';
      }
    );
  };
}
