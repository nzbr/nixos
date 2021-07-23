{ config, lib, pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    qemuOvmf = true;
    onShutdown = "suspend";
    qemuPackage = pkgs.unstable.qemu;
  };

  users.users.nzbr.extraGroups = [ "kvm" "libvirtd" ];
}
