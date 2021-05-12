{ config, lib, pkgs, modulesPath, ... }:
let
  defaultUser = "nzbr";
  syschdemd = import /etc/nixos/syschdemd.nix { inherit lib pkgs config defaultUser; };
in
{
  networking.hostName = "hurricane";

  imports = [
    "${modulesPath}/profiles/minimal.nix"

    ../module/common/boot/grub.nix

    ../module/common.nix

    ../module/desktop/latex.nix
  ];

  # boot.isContainer = true;

  environment.etc = {
    hosts.enable = false;
    "resolv.conf".enable = false;

    "wsl.conf".text = ''
      [automount]
      enabled=true
      mountFsTab=true
      root=/drv/
      options=metadata,uid=1000,gid=100
    '';
  };

  fileSystems = {
    "/" = {
      label = "NixOS";
      fsType = "ext4";
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=4G" ];
    };
  } // lib.listToAttrs (
    map
      (distro: lib.nameValuePair
        ("/drv/"+distro)
        {label = distro; fsType = "ext4"; options = ["defaults" "noauto"];}
      ) ["Arch" "Ubuntu"]
  );

  networking.dhcpcd.enable = false;

  users.users.root = {
    shell = "${syschdemd}/bin/syschdemd";
    extraGroups = [ "root" ]; # Otherwise WSL fails to login as root with "initgroups failed 5"
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable systemd units that don't make sense on WSL
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  systemd.services.firewall.enable = false;
  systemd.services.systemd-resolved.enable = false;
  systemd.services.systemd-udevd.enable = false;

  # Don't allow emergency mode, because we don't have a console.
  systemd.enableEmergencyMode = false;
}
