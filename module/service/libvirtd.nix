{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.service.libvirtd = {
    enable = mkEnableOption "libvirtd";
    # swtpmStateDir = mkStrOpt "/var/lib/swtpm";
  };

  config =
    let
      cfg = config.nzbr.service.libvirtd;
    in
    mkIf cfg.enable {
      virtualisation.libvirtd = {
        enable = true;
        onBoot = "start";
        onShutdown = "suspend";
        qemu = {
          ovmf.enable = true;
          package = pkgs.unstable.qemu;
        };
      };

      security.polkit.enable = true;

      # TPM Emulator for Windows 11 VMs (does not work, TPM is not detected)
      # systemd.services.libvirtd.path = with pkgs; [
      #   swtpm
      #   gnutls
      # ];

      # # This is really cursed, but the state dir needs to be writeable
      # system.activationScripts."swtpm-state-dir" = ''
      #   mkdir -p ${cfg.swtpmStateDir}
      # '';
      # fileSystems."swtpm" = {
      #   mountPoint = "${pkgs.swtpm}/var/lib";
      #   device = cfg.swtpmStateDir;
      #   options = [ "bind" ];
      # };

      users.groups = {
        kvm.members = [ config.nzbr.user ];
        libvirtd.members = [ config.nzbr.user ];
      };
    };
}
