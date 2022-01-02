{ config, lib, inputs, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.nopasswd.enable = mkEnableOption "Empty user passwords and auto-login";

  config = mkIf config.nzbr.nopasswd.enable {
    users.users = {
      "${config.nzbr.user}".passwordFile = mkForce null;
      root.passwordFile = mkForce null;
    };
    services.getty.autologinUser = lib.mkForce config.nzbr.user;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
    security.sudo.wheelNeedsPassword = false;

    services.xserver.displayManager.autoLogin = mkIf config.services.xserver.enable {
      enable = true;
      inherit (config.nzbr) user;
    };
  };
}
