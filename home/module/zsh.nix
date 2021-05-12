{ config, lib, pkgs, ... }:
{
  home.file = {
    zsh-pre = {
      target = ".pre.zsh";
      text = ''
        if [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
          source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
        fi
      '';
    };
  };
}
