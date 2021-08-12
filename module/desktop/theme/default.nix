{ config, lib, pkgs, modulesPath, ... }:
{
  options = with lib; with types; {
    nzbr.theme = {
      accentColor = mkOption {
        default = "#6916A3";
        type = str;
      };
    };
  };

  config =
    let
      cfg = config.nzbr.theme;
    in
    {
      environment.systemPackages = with pkgs; [
        pop-gtk-theme
        local.papirus-icon-theme-mod
      ];

      nixpkgs.overlays = [
        (self: super: {
          pop-gtk-theme = super.pop-gtk-theme.overrideAttrs (oldAttrs: rec {
            patches = with builtins; [ (toFile "accent.patch" (replaceStrings [ "ACCENTCOLOR" ] [ cfg.accentColor ] (readFile ./accent.patch))) ];
          });
        })
      ];
    };
}
