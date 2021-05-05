{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    libreoffice-fresh
    pandoc
    (texlive.combine {
      inherit (texlive)
      scheme-tetex
      dinbrief;
    })
  ];
}
