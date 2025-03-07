{ config, lib, inputs, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.channels = with types; {
    enable = mkEnableOption "Link Flake Source as Channels";
  };

  config = mkIf config.nzbr.channels.enable (
    let
      channelsDrv = pkgs.runCommand "channels" { } ''
        mkdir -p $out
        ${concatStringsSep " && " (mapAttrsToList (name: val: "ln -ns ${val} $out/${name}") inputs)}
        cd $out
        if ! [[ -s nixos ]] && [[ -s nixpkgs ]]; then
          ln -s nixpkgs nixos
        fi
      '';
    in
    {
      system.activationScripts.channels.text = ''
        echo linking channels
        mkdir -p /nix/var/nix/profiles/per-user/root
        ln -nsf ${channelsDrv} /nix/var/nix/profiles/per-user/root/channels
        mkdir -p /nix/var/nix/profiles/per-user/${config.nzbr.user}
        ln -nsf ${channelsDrv} /nix/var/nix/profiles/per-user/${config.nzbr.user}/channels
      '';
    }
  );
}
