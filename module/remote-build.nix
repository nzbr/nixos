{ config, options, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.remoteNixBuild = with types; {
    enable = mkEnableOption "Nix Remote Build Client";
    foreignOnly = mkOption {
      description = "Only enable remote builds for foreign architectures";
      type = types.bool;
      default = true;
    };
    extraBuildMachines = mkOption {
      description = "Additional entries for nix.buildMachines";
      type = options.nix.buildMachines.type;
      default = [ ];
    };
  };

  config =
    let
      cfg = config.nzbr.remoteNixBuild;
    in
    mkIf cfg.enable {
      nix.distributedBuilds = true;
      nix.buildMachines = cfg.extraBuildMachines ++ (
        filter
          (entry: entry.systems != [ ])
          (
            mapAttrsToList
              (n: v:
                let
                  vcfg = v.config.nzbr.service.buildServer;
                in
                {
                  hostName = v.config.nzbr.hostName;
                  sshUser = vcfg.user;
                  sshKey = config.nzbr.assets."ssh/id_ed25519";
                  systems =
                    if cfg.foreignOnly
                    then (filter (s: s != config.nixpkgs.system) vcfg.systems)
                    else vcfg.systems;
                  maxJobs = vcfg.maxJobs;
                  supportedFeatures = v.config.nix.settings.system-features;
                }
              )
              (
                filterAttrs
                  (n: v: (v.config.nzbr.service.buildServer.enable) && (elem config.networking.hostName v.config.nzbr.service.ssh.authorizedSystems))
                  inputs.self.nixosConfigurations
              )
          )
      );
      nix.extraOptions = ''
        builders-use-substitutes = true
      '';
    };
}
