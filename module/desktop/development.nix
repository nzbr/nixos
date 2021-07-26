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

    timeular
  ];

  programs.adb.enable = true;
  users.users.nzbr.extraGroups = [ "adbusers" ];

  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
