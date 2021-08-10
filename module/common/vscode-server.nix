{ config, lib, inputs, pkgs, modulesPath, ... }:
{
  imports = [
    "${inputs.vscode-server}"
  ];

  services.vscode-server.enable = true;
}
