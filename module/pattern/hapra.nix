{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.hapra.enable = mkEnableOption "";

  config = mkIf config.nzbr.pattern.hapra.enable {
    environment.systemPackages = with pkgs; [
      ghdl
      # ghdl-llvm is currently broken https://github.com/NixOS/nixpkgs/issues/113401
      gtkwave
    ];
  };
}
