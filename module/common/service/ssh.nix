{ config, lib, pkgs, modulesPath, ... }:
let
  secrets = ../../../secret;
  keys = with builtins; with lib; # TODO: Restrict to certain hosts (configurable)
    map
      (x: removeSuffix "\n" x)
      (
        map
          (x: readFile (secrets + "/${x.name}/ssh/id_ed25519.pub"))
          (
            filter
              (x:
                (x.type == "directory")
                && (hasAttr "ssh" (readDir (secrets + "/${x.name}")))
                && (hasAttr "id_ed25519.pub" (readDir (secrets + "/${x.name}/ssh")))
              )
              (
                mapAttrsToList
                  (name: type: { name = name; type = type; })
                  (readDir secrets)
              )
          )
      );
in
{
  environment.etc = {
    "ssh/ssh_host_ed25519_key" = {
      mode = "0400";
      source = ../../../secret + "/${config.networking.hostName}/ssh/ssh_host_ed25519_key";
    };
    "ssh/ssh_host_ed25519_key.pub" = {
      mode = "0400";
      source = ../../../secret + "/${config.networking.hostName}/ssh/ssh_host_ed25519_key.pub";
    };
    "ssh/ssh_host_rsa_key" = {
      mode = "0400";
      source = ../../../secret + "/${config.networking.hostName}/ssh/ssh_host_rsa_key";
    };
    "ssh/ssh_host_rsa_key.pub" = {
      mode = "0400";
      source = ../../../secret + "/${config.networking.hostName}/ssh/ssh_host_rsa_key.pub";
    };
  };

  programs.mosh.enable = true;
  programs.ssh.setXAuthLocation = lib.mkForce true;
  services.openssh = {
    enable = true;
    openFirewall = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    permitRootLogin = "yes";
    forwardX11 = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        path = "/etc/ssh/ssh_host_rsa_key";
      }
    ];
    knownHosts = lib.listToAttrs
      (builtins.map
        (hostname: {
          name = hostname;
          value = {
            hostNames = [
              hostname
              "${hostname}.nzbr.de"
              "${hostname}4.nzbr.de"
              "${hostname}6.nzbr.de"
            ];
            publicKeyFile = ../../../secret + "/${hostname}/ssh/ssh_host_ed25519_key.pub";
          };
        })
        (
          lib.mapAttrsToList
            (name: _: lib.removeSuffix ".nix" name)
            (builtins.readDir ../../../machine)
        )
      );
  };

  users.users = {
    root.openssh.authorizedKeys.keys = keys;
    nzbr.openssh.authorizedKeys.keys = keys;
  };
}
