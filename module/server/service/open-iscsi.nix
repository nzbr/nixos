{ config, lib, pkgs, modulesPath, ... }:
let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
in
{
  imports = [
    "${unstableTarball}/nixos/modules/services/networking/iscsi/initiator.nix"
  ];

  environment.systemPackages = with pkgs; [
    unstable.openiscsi
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:${config.networking.hostName}";
    package = pkgs.unstable.openiscsi;
  };
}
