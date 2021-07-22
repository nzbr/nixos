{ config, lib, inputs, pkgs, modulesPath, ... }:
{
  # imports = [
  #   "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/iscsi/initiator.nix"
  # ];

  environment.systemPackages = with pkgs; [
    # unstable.openiscsi
    openiscsi
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:${config.networking.hostName}";
    # package = pkgs.unstable.openiscsi;
    package = pkgs.openiscsi;
  };
}
