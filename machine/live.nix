{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "live";

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"

    ../module/desktop.nix
    ../module/desktop/gnome.nix
  ];

  isoImage = {
    edition = "nzbr";
  };

  users.users.nzbr.uid = 1000;
  services.getty.autologinUser = lib.mkForce "nzbr";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;



  ### FROM https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix ###

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.xserver.displayManager.gdm.autoSuspend = false;
}
