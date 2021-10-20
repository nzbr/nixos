{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.program.java = {
    enable = mkEnableOption "java";
  };

  config =
    let
      cfg = config.nzbr.program.java;
    in
    mkIf cfg.enable {
      programs.java = {
        enable = true;
        # package = pkgs.unstable.adoptopenjdk-openj9-bin-11;
        package = pkgs.unstable.jdk8;
      };
    };
}
