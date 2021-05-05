{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    unstable.jetbrains.idea-ultimate

    vscode
    global
    desktop-file-utils
  ];
}
