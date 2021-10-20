{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "hurricane";

  nzbr = {
    patterns = [ "common" "wsl" "development" "hapra" ];

    service = {
      syncthing.enable = true;
    };

    program = {
      latex.enable = true;
    };
  };

}
