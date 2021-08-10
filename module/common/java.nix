{ config, lib, pkgs, modulesPath, ... }:
{
  programs.java = {
    enable = true;
    # package = pkgs.unstable.adoptopenjdk-openj9-bin-11;
    package = pkgs.unstable.jdk8;
  };
}
