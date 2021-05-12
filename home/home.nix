{ config, lib, pkgs, ... }:
{
  imports = [
    ./module/gtk.nix
    ./module/zsh.nix
  ];
}
