{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ../common/development.nix
  ];

  environment.systemPackages = with pkgs; [
    (jetbrains.idea-ultimate.override { jdk = adoptopenjdk-openj9-bin-11; })

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
