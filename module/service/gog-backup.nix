{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.service.gogBackup = with types; {
    enable = mkEnableOption "download GOG games";
    user = mkOption {
      type = str;
      description = "User to run the service as";
      default = config.nzbr.user;
    };
    schedule = mkOption {
      description = "Schedule for the indexing (in systemd format)";
      type = nullOr str;
      default = null;
    };
    destination = mkOption {
      type = str;
      description = "Where to put the GOG games";
    };
    platform = mkOption {
      type = str;
      description = "Which platform to download games for (w/l/m/a) (, for priority, + for multiple)";
      default = "w+l";
    };
    language = mkOption {
      type = str;
      description = "Which language to download games for";
      default = "en";
    };
    include = mkOption {
      type = str;
      description = "What to download";
      default = "all";
    };
    exclude = mkOption {
      type = nullOr str;
      description = "What not to download";
      default = null;
    };
  };

  config =
    let
      cfg = config.nzbr.service.gogBackup;
    in
    mkIf cfg.enable {

      # TODO: Monitoring (via nix-prefab)

      environment.systemPackages = with pkgs; [
        lgogdownloader
      ];

      systemd = {
        services.gogBackup = {
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
          };
          script = ''
            ${pkgs.lgogdownloader}/bin/lgogdownloader \
              --directory ${cfg.destination} \
              --platform ${cfg.platform} \
              --language ${cfg.language} \
              --include ${cfg.include} \
              ${optionalString (cfg.exclude != null) "--exclude ${cfg.exclude}"} \
              --include-hidden-products \
              --download \
              --save-serials \
              --save-logo \
          '';
        };

        timers.gogBackup = mkIf (cfg.schedule != null) {
          wantedBy = [ "timers.target" ];
          partOf = [ "gogBackup.service" ];
          timerConfig.OnCalendar = cfg.schedule;
        };
      };
    };

}
