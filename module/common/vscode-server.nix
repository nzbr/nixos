{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (builtins.fetchTarball https://github.com/nzbr/nixos-vscode-server/tarball/master)
  ];

  services.vscode-server.enable = true;
}
