{ config, lib, inputs, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.nopasswd.enable = mkEnableOption "Empty user passwords and auto-login";

  config = mkIf config.nzbr.nopasswd.enable {
    users.users = {
      "${config.nzbr.user}".hashedPasswordFile = mkForce null;
      root.hashedPasswordFile = mkForce null;
    };

    nzbr.autologin.enable = true;
  };
}
