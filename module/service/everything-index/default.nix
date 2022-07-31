{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.everythingIndex = with types; mkOption {
    default = { };
    description = "Directories to regularly create an everthing index for";
    type = listOf (submodule ({ config', ... }: {
      options = {
        name = mkOption {
          type = str;
          default = baseNameOf config'.path;
        };
        path = mkOption {
          description = "Path to the directory to create the index for";
          type = str;
        };
        schedule = mkOption {
          description = "Schedule for the indexing (in crontab format)";
          type = str;
        };
      };
    }));
  };

  config =
    let
      cfg = config.nzbr.everythingIndex;
    in
    {
      systemd = {
        services = mapListToAttrs
          (entry:
            nameValuePair
              "everything-index-${entry.name}"
              {
                script =
                  let
                    index = pkgs.substitueAll {
                      name = "everything-index";
                      src = ./index.ps1;
                      isExecutable = true;
                      inherit (pkgs) powershell;
                    };
                  in
                  "${index} ${entry.path}";
              }
          )
          (cfg);

        timers = mapListToAttrs
          (entry:
            nameValuePair
              "everything-index-${entry.name}"
              {
                wantedBy = [ "timers.target" ];
                partOf = [ "everything-index-${entry.name}.service" ];
                timerConfig.OnCalendar = entry.schedule;
              }
          )
          (cfg);
      };
    };

}
