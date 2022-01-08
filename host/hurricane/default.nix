{ config, lib, pkgs, modulesPath, ... }:
{
  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "wsl" "development" "hapra" ];
    pattern.development.guiTools = true;

    remoteNixBuild = {
      enable = true;
      extraBuildMachines = [
        # {
        #   hostName = "comet";
        #   sshUser = "nix-on-droid";
        #   sshKey = config.nzbr.assets."ssh/id_ed25519";
        #   systems = [ "aarch64-linux" ];
        #   maxJobs = 4;
        #   supportedFeatures = [ ];
        # }
      ];
    };

    service = {
      syncthing.enable = true;
    };

    program = {
      latex.enable = true;
    };
  };
}
