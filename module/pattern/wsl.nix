{ config, lib, inputs, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.pattern.wsl = with types; {
    enable = mkEnableOption "Windows Subsystem for Linux guest";
    automountPath = mkStrOpt "/drv";
  };

  config =
    let
      cfg = config.nzbr.pattern.wsl;
    in
    mkIf cfg.enable (
      let
        automountPath = cfg.automountPath;
        syschdemd = import "${inputs.nixos-wsl}/syschdemd.nix" { inherit lib pkgs config automountPath; defaultUser = config.nzbr.user; };
      in
      {
        nzbr.pattern.common.enable = true;
        nzbr.desktop.gnome.enable = true;

        # Pretend that there is a bootloader
        boot.loader.grub.enable = false;
        system.build.installBootLoader = pkgs.writeShellScript "fake-bootloader" "";

        # basic gui environment
        environment.noXlibs = lib.mkForce false;
        # services.xserver.desktopManager.lxqt.enable = true;
        services.xserver.displayManager.gdm.enable = lib.mkForce false;
        services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
        networking.networkmanager.enable = lib.mkForce false;

        environment = {
          systemPackages = with pkgs; [
            chromium
            virt-manager

            (pkgs.writeShellScriptBin "winpath" ''
              DIR="$PWD"
              if [ -z ''${1:-} ]; then
                DIR="$(realpath $1)"
              fi
              # This is completely sane, idk what you mean
              echo $DIR | sed -E "s|(.*)|//WSL\$/''${WSL_DISTRO_NAME}\1|;s|//WSL\\\$/''${WSL_DISTRO_NAME}/drv/(.)|\\U\\1:|;s|/|\\\\|g"
            '')
          ];

          variables = {
            DISPLAY = ":1";

            # Theme config
            # QT_QPA_PLATFORMTHEME = "gtk2"; # already set somewhere else?
            XDG_CURRENT_DESKTOP = "gnome";
          };

          etc = {
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
        };

        system.activationScripts = {
          # Copy application launchers for WSLg
          copy-launchers.text = ''
            for x in applications icons; do
              echo "Copying /usr/share/$x"
              ${pkgs.rsync}/bin/rsync -ar --delete $systemConfig/sw/share/$x/. /usr/share/$x
            done
          '';
          wsl-cleanup.text = ''
            rmdir /wsl* || true
          '';
        };

        home-manager.users.root.home.file.".wsld.toml".text = ''
          [x11]
          display = 1
        '';
        systemd.services."wsld" = {
          path = [ pkgs.local.wsld ];
          script = "wsld";
          wantedBy = [ "multi-user.target" ];
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
              ("/drv/" + distro)
              { label = distro; fsType = "ext4"; options = [ "defaults" "noauto" ]; }
            ) [ "Arch" "Ubuntu" ]
        );

        networking.dhcpcd.enable = false;

        users.users = {
          root = {
            shell = "${syschdemd}/bin/syschdemd";
            extraGroups = [ "root" ]; # Otherwise WSL fails to login as root with "initgroups failed 5"
          };
          ${config.nzbr.user} = {
            uid = 1000;
            extraGroups = [ "docker" ];
          };
        };

        i18n.supportedLocales = [
          "en_US.UTF-8/UTF-8"
        ];

        environment.extraInit = ''
          # Include Windows %PATH% in Linux $PATH.
          PATH="$PATH:$WSLPATH"

          # SSH Agent
          if ! [ -f /tmp/ssh-agent.''${USER}.pid ]; then
            ssh-agent >/tmp/ssh-agent.''${USER}.env
          fi
          source /tmp/ssh-agent.''${USER}.env >/dev/null
        '';

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
          wants = [ "user@${config.nzbr.user}.service" ];
          wantedBy = [ "multi-user.target" ];
        };

        nzbr.home.users = [ config.nzbr.user ];

      }
    );
}
