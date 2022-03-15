{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  boot.loader.efi.canTouchEfiVariables = mkForce false;

  nzbr = {
    deployment.targetHost = "192.168.88.131";
    patterns = [ "desktop" "vmware" "development" ];
    pattern.development.guiTools = true;

    agenix.enable = mkForce true;
    nopasswd.enable = false;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  systemd.mounts = [
    {
      what = "${pkgs.open-vm-tools}/bin/vmhgfs-fuse";
      where = "/drv";
      type = "fuse";
      options = "allow_other,uid=1000,gid=100,exec";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  networking.firewall.checkReversePath = false;
}
