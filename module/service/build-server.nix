{ config, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.service.buildServer = with types; {
    enable = mkEnableOption "Nix Remote Build Server";
    user = mkStrOpt "nixbuild";
    maxJobs = mkIntOpt 1;
    systems = mkOption {
      description = "Architectures that are supported by this server";
      type = listOf str;
    };
  };

  config =
    let
      cfg = config.nzbr.service.buildServer;
    in
    mkIf cfg.enable {
      nzbr.service.buildServer = {
        systems = mkDefault [ config.nzbr.system ];
      };

      boot.binfmt.emulatedSystems =
        let
          current = config.nzbr.system;
          arch = sys: lib.systems.elaborate { system = sys; };
        in
        filter
          (x: !(arch current).isCompatible (arch x)) # Only enable architectures that are not natively supported anyway
          cfg.systems;

      nix.extraOptions = ''
        extra-platforms = ${toString cfg.systems}
      '';

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
