let
  branding = ./nixos-branding.png;
in
{ config, lib, pkgs, modulesPath, ... }:
{
  boot.plymouth = {
    enable = true;
    themePackages = [ ];
    theme = "bgrt";
  };

  nixpkgs.overlays = [
    (self: super: {
      plymouth = super.unstable.plymouth;
    })
  ];
}
