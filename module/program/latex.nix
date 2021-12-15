{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.program.latex = {
    enable = mkEnableOption "LaTeX";
  };

  config = mkIf config.nzbr.program.latex.enable {
    environment.systemPackages = with pkgs; [
      pandoc
      pandoc-plantuml-filter

      tectonic
    ];
  };
}
