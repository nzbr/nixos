{ config, lib, inputs, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.autologin.enable = mkEnableOption "Automatically login the default user";

  config = mkIf config.nzbr.autologin.enable {
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
