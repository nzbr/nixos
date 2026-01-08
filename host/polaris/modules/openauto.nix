{ config, lib, pkgs, ... }:
{

  nixpkgs.overlays = [
    (final: prev: {
      h264bitstream = prev.callPackage ../pkgs/h264bitstream.nix { };
      aasdk = prev.callPackage ../pkgs/aasdk.nix { inherit (final) openDsh; };
      qtgstreamer = prev.libsForQt5.callPackage ../pkgs/qtgstreamer.nix { };
      openauto = prev.libsForQt5.callPackage ../pkgs/openauto.nix { inherit (final) aasdk h264bitstream qtgstreamer; };
      openDsh = prev.libsForQt5.callPackage ../pkgs/openDsh.nix { inherit (final) openauto aasdk; };
      openautoLauncher = prev.callPackage ../pkgs/launcher.nix { inherit (final) openauto openDsh; };
    })
  ];

  environment.systemPackages = [
    pkgs.openauto
    pkgs.openDsh
    pkgs.openautoLauncher
  ];

  system.build = {
    aasdk = pkgs.aasdk;
    openauto = pkgs.openauto;
    h264bitstream = pkgs.h264bitstream;
    qtgstreamer = pkgs.qtgstreamer;
    openDsh = pkgs.openDsh;
  };

}
