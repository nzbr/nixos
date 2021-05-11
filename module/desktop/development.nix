{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    unstable.jetbrains.idea-ultimate

    unstable.vscode
    global
    desktop-file-utils

    unstable.tabnine
  ];
}
