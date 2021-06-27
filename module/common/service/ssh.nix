{ config, lib, pkgs, modulesPath, ... }:
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
}
