{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    python3.withPackages
    (python-packages: with python-packages; [
      virtualenv
    ])
  ];
}
