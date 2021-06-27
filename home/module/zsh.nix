{ config, lib, pkgs, ... }:
{
  home.file = {
    pre-zsh = {
      target = ".pre.zsh";
      text = ''
        for hook in ~/.config/shell-hooks/*.pre; do
          source "$hook"
        done
      '';
    };
    post-zsh = {
      target = ".post.zsh";
      text = ''
        for hook in ~/.config/shell-hooks/*.post; do
          source "$hook"
        done
      '';
    };
    hm-shell-hook = {
      target = ".config/shell-hooks/home-manager.pre";
      text = ''
        if [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
          source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
        fi
      '';
    };
    nix-run-hook = {
      target = ".config/shell-hooks/nix-run.post";
      text = ''
        function nr {
          nix-shell -p "$1" --command "$@"
        }
      '';
    };
  };
}
