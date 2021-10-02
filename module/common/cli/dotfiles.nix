{ config, lib, pkgs, modulesPath, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      stow
      pwgen
    ];

    extraInit = ''
      if ! [ -d $HOME/.dotfiles ]; then
        curl -fsSL https://raw.githubusercontent.com/nzbr/dotfiles/master/control.sh | bash
      fi
    '';
  };
}
