{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (builtins.fetchTarball https://github.com/msteen/nixos-vscode-server/tarball/master)
  ];

  services.vscode-server.enable = true;
  # TODO: Auto-Enable user-service with home manager
}
