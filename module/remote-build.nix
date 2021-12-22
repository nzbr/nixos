{ config, options, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.remoteNixBuild = with types; {
    enable = mkEnableOption "Nix Remote Build Client";
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
        mapAttrsToList
          (n: v:
            let
              vcfg = v.config.nzbr.service.buildServer;
            in
            {
              hostName = "${v.config.networking.hostName}.nzbr.github.beta.tailscale.net";
              sshUser = vcfg.user;
              sshKey = config.nzbr.assets."ssh/id_ed25519";
              systems = vcfg.systems;
              maxJobs = vcfg.maxJobs;
              supportedFeatures = v.config.nix.systemFeatures;
            }
          )
          (
            filterAttrs
              (n: v: (v.config.nzbr.service.buildServer.enable) && (elem config.networking.hostName v.config.nzbr.service.ssh.authorizedSystems))
              inputs.self.packages.${system}.nixosConfigurations
          )
      );
      nix.extraOptions = ''
        builders-use-substitutes = true
      '';
    };
}
