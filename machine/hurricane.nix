{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "hurricane";

  imports = [
    ../module/wsl.nix

    ../module/common/development.nix
    ../module/common/service/syncthing.nix

    ../module/desktop/latex.nix
    ../module/desktop/development.nix
  ];
}
