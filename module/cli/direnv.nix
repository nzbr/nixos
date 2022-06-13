{ config, pkgs, lib, ... }:
with builtins; with lib; {
  options.nzbr.cli.direnv = with types; {
    enable = mkEnableOption "Enables automatic usage of nix-shell environments with direnv and direnv";
  };

  config = mkIf config.nzbr.cli.direnv.enable {
    nzbr.home.config = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    programs.bash.interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';

    programs.zsh.interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';
  };
}
