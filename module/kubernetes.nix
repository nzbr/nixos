{ config, lib, pkgs, ... }:
with buitlins; with lib; {
  options.nzbr.kubernetes = with types; {
    enable = mkEnableOption "Kubernetes Deployments";
  };
}
