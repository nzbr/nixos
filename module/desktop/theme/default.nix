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
        local.papirus-icon-theme-mod

        (pop-gtk-theme.overrideAttrs (oldAttrs: rec {
          patches = with builtins; [ (toFile "pop-gtk.patch" (replaceStrings [ "ACCENTCOLOR" ] [ cfg.accentColor ] (readFile ./pop-gtk.patch))) ];
        }))
      ];

      nixpkgs.overlays = [
        (self: super: {
          gnome = super.gnome.overrideScope' (self': super': {
            gnome-shell = super'.gnome-shell.overrideAttrs (oldAttrs: rec {
              patches = with builtins; oldAttrs.patches ++ ([ (toFile "gnome-shell.patch" (replaceStrings [ "ACCENTCOLOR" ] [ cfg.accentColor ] (readFile ./gnome-shell.patch))) ]);
            });
          });
        })
      ];
    };
}
