{ config, lib, pkgs, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "wsl" "development" ];
    pattern.development.guiTools = true;

    remoteNixBuild.enable = true;

    program = {
      latex.enable = true;
    };
  };
}
