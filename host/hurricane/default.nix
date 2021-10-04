{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "hurricane";

  nzbr = {
    patterns = [ "wsl" "development" "hapra" ];

    service = {
      syncthing.enable = true;
    };

    program = {
      latex.enable = true;
    };
  };

}
