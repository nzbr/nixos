{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    pandoc
    (texlive.combine {
      inherit (texlive)
      scheme-tetex
      dinbrief;
    })
    ragon.pandocode
  ];
}
