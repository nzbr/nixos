{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    desktop-file-utils
    global
    go
    python3
    unstable.dotnet-sdk_5
    unstable.tabnine
  ];
}
