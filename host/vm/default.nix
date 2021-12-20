{ config, lib, pkgs, ... }:
{
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" ];
    deployment.substituteOnDestination = false;
  };
}
