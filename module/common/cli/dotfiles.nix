let
  script = ''
    if ! [ -d $HOME/.dotfiles ]; then
      curl -fsSL https://raw.githubusercontent.com/nzbr/dotfiles/master/control.sh | bash
    fi
  '';
in
{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    stow
  ];

  programs.zsh.interactiveShellInit = script;
  programs.bash.interactiveShellInit = script;
}
