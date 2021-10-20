{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.printing = with types; {
    enable = mkEnableOption "printing services";
  };

  config =
    let
      cfg = config.nzbr.service.printing;
    in
    mkIf cfg.enable {
      services.printing = {
        enable = true;
        drivers = with pkgs; [
          hplip
          postscript-lexmark
        ];
      };
    };
}
