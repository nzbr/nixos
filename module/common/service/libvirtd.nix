{ config, lib, pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    qemuOvmf = true;
    onShutdown = "suspend";
    qemuPackage = pkgs.unstable.qemu;
  };
}
