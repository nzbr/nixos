{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ../common/development.nix
  ];

  environment.systemPackages = with pkgs; [
    jetbrains.idea-ultimate

    unstable.gitkraken
    unstable.insomnia
    vscode

    unstable.timeular

    scrcpy
  ];

  programs.adb.enable = true;
  users.users.nzbr.extraGroups = [ "adbusers" ];

  services.udev.packages = [
    pkgs.android-udev-rules
  ];

}
