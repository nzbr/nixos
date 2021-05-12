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
    knownHosts = {
      # storm = {
      #   hostNames = [
      #     "storm.nzbr.de"
      #     "storm6.nzbr.de"
      #   ];
      #   publicKeyFile = ../secret/storm/ssh/ssh_host_ed25519_key.pub;
      # };
      # avalanche = {
      #   hostNames = [
      #     "avalanche.nzbr.de"
      #     "avalanche6.nzbr.de"
      #   ];
      #   publicKeyFile = ../secret/avalanche/ssh/ssh_host_ed25519_key.pub;
      # };
      # earthquake = {
      #   hostNames = [
      #     "earthquake.nzbr.de"
      #   ];
      #   publicKeyFile = ../secret/earthquake/ssh/ssh_host_ed25519_key.pub;
      # };
    };
  };
}
