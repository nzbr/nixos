{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    pandoc
    (texlive.combine {
      inherit (texlive)
      scheme-medium

      dinbrief
      ;
    })
    ragon.pandocode
  ];
}
