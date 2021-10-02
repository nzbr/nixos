{ config, lib, pkgs, modulesPath, root, ... }:
let
  secrets = "${root}/host";
  keys = with builtins; with lib; # TODO: Restrict to certain hosts (configurable)
    map
      (x: removeSuffix "\n" x)
      (
        map
          (x: readFile (secrets + "/${x.name}/ssh/id_ed25519.pub"))
          (
            filter
              (x:
                (x.value == "directory")
                && (hasAttr "ssh" (readDir (secrets + "/${x.name}")))
                && (hasAttr "id_ed25519.pub" (readDir (secrets + "/${x.name}/ssh")))
              )
              (
                mapAttrsToList
                  (name: type: nameValuePair name type)
                  (readDir secrets)
              )
          )
      );
in
{

  programs.mosh.enable = true;
  programs.ssh = {
    setXAuthLocation = lib.mkForce true;
    startAgent = true;
  };
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
        (hostname:
          lib.nameValuePair
            hostname
            {
              hostNames = [
                hostname
                "${hostname}.nzbr.de"
                "${hostname}4.nzbr.de"
                "${hostname}6.nzbr.de"
              ];
              publicKeyFile = "${root}/host-keys/${hostname}/ssh_host_ed25519_key.pub";
            }
        )
        (
          lib.mapAttrsToList
            (name: _: name)
            (builtins.readDir ../../../host)
        )
      );
  };

  users.users = {
    root.openssh.authorizedKeys.keys = keys;
    nzbr.openssh.authorizedKeys.keys = keys;
  };
}
