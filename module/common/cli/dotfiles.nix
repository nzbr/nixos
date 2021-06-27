{ config, lib, pkgs, modulesPath, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      stow
    ];

    etc."shell-hooks/00-dotfiles.sh" = {
      mode = "0755";
      text = ''
        if ! [ -d $HOME/.dotfiles ]; then
          curl -fsSL https://raw.githubusercontent.com/nzbr/dotfiles/master/control.sh | bash
        fi
      '';
    };
  };
}
