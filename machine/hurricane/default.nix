{ config, lib, pkgs, modulesPath, root, ... }:
{
  networking.hostName = "hurricane";

  imports = [
    "${root}/module/wsl.nix"

    "${root}/module/common/development.nix"
    "${root}/module/common/service/syncthing.nix"

    "${root}/module/desktop/latex.nix"
    "${root}/module/desktop/development.nix"
  ];

}
