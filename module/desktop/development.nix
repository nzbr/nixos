{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ../common/development.nix
  ];

  environment.systemPackages = with pkgs.unstable; [
    gitkraken
    insomnia
    jetbrains.idea-ultimate
    tabnine
    vscode

    teams
    timeular
  ];
}
