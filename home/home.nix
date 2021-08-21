{ config, lib, pkgs, ... }:
{
  imports = [
    ./module/git.nix
    ./module/gnome.nix
    ./module/theme.nix
    ./module/zsh.nix
    ./module/ssh.nix
  ];

  home.file.cache-marker = {
    target = ".cache/CACHEDIR.TAG";
    text = ''
      Signature: 8a477f597d28d172789f06886806bc55
    '';
  };
}
