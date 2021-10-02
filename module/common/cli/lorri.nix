{ config, lib, pkgs, modulesPath, ... }:
{
  services.lorri.enable = true;

  environment = {
    systemPackages = with pkgs; [
      direnv
    ];
  };

  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"
  '';

  programs.zsh.interactiveShellInit = ''
    eval "$(direnv hook zsh)"
  '';
}
