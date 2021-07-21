{ config, lib, inputs, pkgs, modulesPath, ... }:
let
  defaultUser = "nzbr";
  syschdemd = import "${inputs.nixos-wsl}/syschdemd.nix" { inherit lib pkgs config defaultUser; };
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"

    ./common.nix
    ./common/boot/grub.nix
    ./gui-base.nix
  ];

  # basic gui environment
  # services.xserver.desktopManager.lxqt.enable = true;
  # environment.systemPackages = with pkgs; [
  #   unstable.gnome3.gnome-tweak-tool
  # ];
  # programs.dconf.enable = true;
  # services.dbus.packages = with pkgs; [ unstable.gnome3.dconf ];

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

    # Set environment variables for WSLg
    "shell-hooks/10-wslg.sh" = {
      mode = "0755";
      text = ''
        export XDG_RUNTIME_DIR=/drv/wslg/runtime-dir
        export PULSE_SERVER=/drv/wslg/PulseServer
        export WAYLAND_DISPLAY=wayland-0
        export DISPLAY=:0
        export WSL_INTEROP="$(find /run/WSL -name '*_interop' | sort -V | tail -1)"

        export QT_QPA_PLATFORMTHEME=gtk2
        export XDG_CURRENT_DESKTOP=gnome
      '';
      };
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

  users.users = {
    root = {
      shell = "${syschdemd}/bin/syschdemd";
      extraGroups = [ "root" ]; # Otherwise WSL fails to login as root with "initgroups failed 5"
    };
    "${defaultUser}" = {
      uid = 1000;
      extraGroups = [ "docker" ];
    };
  };

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];

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

  # Force-Start user daemon for the default user
  systemd.targets.user-daemon = {
    wants = [ "user@${defaultUser}.service" ];
    wantedBy = [ "multi-user.target" ];
  };

}
