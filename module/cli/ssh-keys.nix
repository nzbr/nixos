{ config, lib, inputs, system, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{
  config = mkMerge [
    (mkIf
      (
        root != null
        && (hasAttr "ssh" (readDir "${root}/host/${config.networking.hostName}"))
        && (hasAttr "id_ed25519.age" (readDir "${root}/host/${config.networking.hostName}/ssh"))
      )
      {
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
      })
    (mkIf
      (
        root != null
        && (hasAttr "ssh" (readDir "${root}/host/${config.networking.hostName}"))
        && (hasAttr "permafrost.age" (readDir "${root}/host/${config.networking.hostName}/ssh"))
      )
      {
        age.secrets."ssh/permafrost" = {
          owner = "root";
          mode = "0600";
        };
        programs.ssh.extraConfig = ''
          Host permafrost-backup
            HostName permafrost.dragon-augmented.ts.net
            User ${config.networking.hostName}
            IdentityFile ${config.nzbr.assets."ssh/permafrost"}
          Host hetzner
            HostName u523435.your-storagebox.de
            Port 23
            IdentityFile ${config.nzbr.assets."ssh/permafrost"}
        '';
      })
  ];
}
