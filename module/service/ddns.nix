{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options = with types; {
    nzbr.service.ddns = {
      enable = mkEnableOption "Enables CloudFlare DDNS to the specified domain and all subdomains";
      domain = strOption;
      passwordFile = mkStrOpt config.nzbr.assets."cloudflareKey";
      ipv4 = mkBoolOpt false;
      ipv6 = mkBoolOpt true;
    };
  };

  config =
    let
      cfg = config.nzbr.service.ddns;
      dir = "/run/inadyn";
      dataDir = "${dir}/data";
      cacheDir = "${dir}/cache";
    in
    mkIf cfg.enable {
      users.users.inadyn = {
        isSystemUser = true;
        group = "inadyn";
      };
      users.groups.inadyn = { };

      systemd = {
        services.ddns =
          let
            confFile = toFile "inadyn.cfg" ''
              period = 180
              user-agent = Mozilla/5.0
              allow-ipv6 = true
              ${optionalString cfg.ipv4 ''
                provider cloudflare:4 {
                  checkip-server = api4.ipify.org
                  username = ${cfg.domain}
                  password = ${cfg.password}
                  hostname = ${cfg.domain}
                }
              ''}
              ${optionalString cfg.ipv6 ''
                provider cloudflare:6 {
                  checkip-server = api6.ipify.org
                  username = ${cfg.domain}
                  password = ${cfg.password}
                  hostname = ${cfg.domain}
                }
              ''}
            '';
          in
          {
            description = "inadyn dynamic DNS client";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [ bash inadyn ];
            serviceConfig = {
              User = "inadyn";
              RuntimeDirectory = dataDir;
              StateDirectory = dataDir;
            };
            preStart = ''
              PASSFILE=${cfg.passwordFile}
              sed 's/PASSWORD/''${cat $PASSFILE}/' > ${dataDir}/inadyn.cfg
            '';
            script = "inadyn -n --cache-dir=${cacheDir} -f ${dataDir}/inadyn.cfg";
          };
        tmpfiles.rules = [
          "d ${dataDir} 1700 inadyn root"
          "d ${cacheDir} 1700 inadyn root"
        ];
      };
    };
}
