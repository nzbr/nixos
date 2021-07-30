{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ../common/development.nix
  ];

  environment.systemPackages = with pkgs; [
    unstable.jetbrains.idea-ultimate

    unstable.gitkraken
    unstable.insomnia
    unstable.vscode

    unstable.timeular
  ];

  programs.adb.enable = true;
  users.users.nzbr.extraGroups = [ "adbusers" ];

  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
