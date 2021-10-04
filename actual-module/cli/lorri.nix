{ config, pkgs, lib, ... }:
with builtins; with lib; {
  options.nzbr.cli.lorri = with types; {
    enable = mkEnableOption "Enables automatic usage of nix-shell environments with direnv and lorri";
  };

  config = mkIf config.nzbr.cli.lorri.enable {
    services.lorri.enable = true;

    environment.systemPackages = with pkgs; [
      direnv
    ];

    programs.bash.interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';

    programs.zsh.interactiveShellInit = ''
      eval "$(direnv hook zsh)"
    '';
  };
}
