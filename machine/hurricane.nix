{ config, lib, pkgs, modulesPath, ... }:
{
  networking.hostName = "hurricane";

  imports = [
    ../module/wsl.nix

    ../module/desktop/latex.nix
  ];
}
