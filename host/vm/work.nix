{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  nzbr = {
    deployment.targetHost = "192.168.110.128";
    patterns = [ "desktop" "vmware" "development" ];
    pattern.development.guiTools = true;

    agenix.enable = mkForce true;
    nopasswd.enable = false;
  };

  systemd.mounts = [
    {
      what = "${pkgs.open-vm-tools}/bin/vmhgfs-fuse";
      where = "/drv";
      type = "fuse";
      options = "allow_other,uid=1000,gid=100,exec";
      wantedBy = [ "multi-user.target" ];
    }
  ];
}
