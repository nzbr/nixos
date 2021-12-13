{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.service.fprintd = with types; {
    enable = mkEnableOption "Fingerprint reader";
  };

  config =
  let
    cfg = config.nzbr.service.fprintd;
  in
  mkIf cfg.enable {
    services.fprintd = {
      enable = true;
    };
  };
}
