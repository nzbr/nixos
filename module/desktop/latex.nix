{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    pandoc
    pandoc-plantuml-filter

    (texlive.combine {
      inherit (texlive)
      scheme-medium

      dinbrief
      ;
    })

    ragon.pandocode
  ];
}
