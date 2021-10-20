{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
let
  branding = ./nixos-branding.png;
in
{
  options.nzbr.boot.plymouth = {
    enable = mkEnableOption "Plymouth boot splash screen";
  };

  config = mkIf config.nzbr.boot.plymouth.enable {
    boot.plymouth = {
      enable = true;
      themePackages = [ ];
      theme = "bgrt";
    };

    # nixpkgs.overlays = [
    #   (self: super: {
    #     plymouth = super.unstable.plymouth;
    #   })
    # ];
  };
}
