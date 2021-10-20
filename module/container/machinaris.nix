{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.container.machinaris.enable = mkEnableOption "Machinaris container";

  config = mkIf config.nzbr.container.machinaris.enable {
    virtualisation.oci-containers.containers.machinaris = {
      image = "ghcr.io/guydavis/machinaris";
      environment = {
        TZ = "Europe/Berlin";
      };
      ports = [
        "8444:8444"
        "8926:8926"
      ];
      volumes = [
        "/storage/chia/config:/root/.chia"
        "/storage/chia/plots:/plots"
        "/storage/chia/.plotting:/plotting"
      ];
      extraOptions = [
        ("--hostname=" + config.networking.hostName)
      ];
    };
  };
}
