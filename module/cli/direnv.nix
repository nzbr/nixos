{ config, pkgs, lib, ... }:
with builtins; with lib; {
  options.nzbr.cli.direnv = with types; {
    enable = mkEnableOption "Enables automatic usage of nix-shell environments with direnv and direnv";
  };

  config = mkIf config.nzbr.cli.direnv.enable {
    services.direnv.enable = true;

    environment.systemPackages = with pkgs; [
      direnv
      nix-direnv
    ];

    programs.bash.interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';

    programs.zsh.interactiveShellInit = ''
      eval "$(direnv hook zsh)"
    '';
  };
}
