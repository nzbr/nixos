{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "wsl" "development" ];
    pattern.development.guiTools = true;

    remoteNixBuild.enable = true;
  };

  services.openssh = {
    enable = true;
    ports = [
      2222
    ];
  };

  fileSystems."/tmp".options = mkForce [ "size=32G" ];

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";
}
