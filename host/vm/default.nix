{ config, lib, pkgs, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" ];
    deployment.substituteOnDestination = false;

    agenix.enable = false;
    nopasswd.enable = mkDefault true;
    autologin.enable = mkDefault true;
  };

  # Make the configuration build
  boot.loader.grub.device = mkDefault "nodev";
  fileSystems."/" = mkDefault {
    label = "NixOS";
    fsType = "ext4";
  };

  systemd.network.enable = mkDefault true;
  systemd.network.networks."lan" = {
    enable = mkDefault true;
    matchConfig.Name = "e*";
    DHCP = "ipv4";
  };

}
