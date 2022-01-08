{ config, lib, pkgs, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" ];
    deployment.substituteOnDestination = false;
  };

  # Make the configuration build
  boot.loader.grub.device = mkDefault "nodev";
  fileSystems."/" = mkDefault {
    label = "NixOS";
    fsType = "ext4";
  };
}
