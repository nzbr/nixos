let
  script = ''
    if [ -d /etc/shell-hooks ]; then
      for hook in /etc/shell-hooks/*; do
        source $hook
      done
    fi
  '';
in
{ config, lib, pkgs, modulesPath, ... }:
{
  programs.zsh.interactiveShellInit = script;
  programs.bash.interactiveShellInit = script;
}
