{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  options.nzbr.cli.dotfiles = with types; {
    enable = mkEnableOption "nzbr's dotfiles";
    users = mkOption {
      type = listOf str;
      default = [ "root" config.nzbr.user ];
    };
  };

  config =
    let
      cfg = config.nzbr.cli.dotfiles;
      extraPath = concatStringsSep ":" (flatten (map (pkg: [ "${pkg}/bin" "${pkg}/sbin" ]) config.environment.systemPackages));
    in
    mkIf cfg.enable {
      # TODO: Replace with the same stuff the live ISO uses
      environment = {
        systemPackages = with pkgs; [
          unstable.xstow
          pwgen
        ];
      };

      system.activationScripts.copy-dotfiles = {
        deps = [ "etc" ];
        text =
          let
            script = pkgs.writeScript "dotfiles.sh" ''
              # Add all installed packages to path
              PATH=$PATH:${extraPath}
              echo "Setting up dotfiles for $(whoami)..."
              rsync -ar --delete "${inputs.dotfiles}/." "$HOME/.dotfiles"
              mkdir -p $HOME/{.cache,.config,.local/{bin,share,lib}}
              touch $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
              export DOT_NOINSTALL=1 && source $HOME/.dotfiles/control.sh && autolink_all
              rm -f $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
              sha256sum $HOME/.zsh_plugins.txt $HOME/.zshrc > $HOME/.zsh.sha
              mkdir -p "$HOME/.cache/antibody"
              ln -sf "${pkgs.antibody}/bin/antibody" "$HOME/.cache/antibody/antibody"
            '';
          in
          builtins.concatStringsSep "\n" (
            map
              (user: "${pkgs.sudo}/bin/sudo -u ${user} ${pkgs.bash}/bin/bash ${script} |& ${pkgs.coreutils}/bin/tee /var/log/dotfiles-${user}.log")
              cfg.users
          );
      };
    };
}
