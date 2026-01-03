{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.desktop.theme = with types; {
    enable = mkEnableOption "Theme config";
    accentColor = mkOption {
      default = "#6916A3";
      type = str;
    };
  };

  config =
    let
      cfg = config.nzbr.desktop.theme;
    in
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        # local.papirus-icon-theme-mod

        (pop-gtk-theme.overrideAttrs (oldAttrs: rec {
          patches = [ (pkgs.replaceVarsWith { name = "pop-gtk.patch"; src = ./pop-gtk.patch; replacements = { inherit (cfg) accentColor; }; }) ];
        }))
      ];

      nixpkgs.overlays = [
        (self: super: {
          gnome = super.gnome.overrideScope (self': super': {
            # gnome-shell = super'.gnome-shell.overrideAttrs (oldAttrs: rec {
            #   patches = with builtins; oldAttrs.patches ++ ([ (toFile "gnome-shell.patch" (replaceStrings [ "ACCENTCOLOR" ] [ cfg.accentColor ] (readFile ./gnome-shell.patch))) ]);
            # });
          });
        })
      ];

      nzbr.home.config = {
        gtk = {
          iconTheme = {
            # package = pkgs.local.papirus-icon-theme-mod;
            name = "Papirus-dark";
          };
          theme = {
            # package = pkgs.pop-gtk-theme;
            name = "Pop-dark";
          };
        };
      };
    };
}
