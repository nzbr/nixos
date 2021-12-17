{ config, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.service.buildServer = with types; {
    enable = mkEnableOption "Nix Remote Build Server";
    user = mkStrOpt "nixbuild";
    maxJobs = mkIntOpt 1;
    systems = mkOption {
      description = "Architectures that are supported by this server";
      default = [ "x86_64-linux" ];
      type = listOf str;
    };
  };

  config =
    let
      cfg = config.nzbr.service.buildServer;
    in
    mkIf cfg.enable {
      users = {
        users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.user;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
        };
        groups.${cfg.user} = { };
      };

      nix.trustedUsers = [ cfg.user ];
    };
}
