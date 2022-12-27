{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "wsl" "development" ];
    pattern.development.guiTools = true;
  };
}
