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
        wsl = {
          enable = true;
          inherit (cfg) automountPath;
          automountOptions = "metadata,uid=1000,gid=100,case=dir";
          defaultUser = config.nzbr.user;
          startMenuLaunchers = true;
          # docker.enable = mkDefault true;
          docker-native.enable = mkDefault true;

          # interop.register = mkDefault false;
        };

        nzbr.pattern.common.enable = true;
        nzbr.desktop.gnome.enable = true;

        nzbr.cli.git.enable = mkForce false; # Don't break window's git

        services.xserver.displayManager.gdm.enable = lib.mkForce false;
        services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
        networking.networkmanager.enable = lib.mkForce false;

        environment = {
          systemPackages = with pkgs; [
            chromium
            virt-manager
            wslu

            (pkgs.writeShellScriptBin "winpath" ''
              DIR="$PWD"
              if [ -n ''${1:-} ]; then
                DIR="$(realpath $1)"
              fi
              # This is completely sane, idk what you mean
              echo $DIR | sed -E "s|(.*)|//WSL\$/''${WSL_DISTRO_NAME}\1|;s|//WSL\\\$/''${WSL_DISTRO_NAME}/drv/(.)|\\U\\1:|;s|/|\\\\|g"
            '')
          ];

          variables = {
            # Theme config
            # QT_QPA_PLATFORMTHEME = "gtk2"; # already set somewhere else?
            XDG_CURRENT_DESKTOP = "gnome";
          };
        };

        system.activationScripts = {
          wsl-cleanup.text = ''
            for x in $(${pkgs.findutils}/bin/find / -maxdepth 1 -name 'wsl*'); do
              rmdir $x || true
            done
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
          "/tmp" = {
            device = "tmpfs";
            fsType = "tmpfs";
            options = [ "size=4G" ];
          };
          "/proc" = {
            device = "proc";
            fsType = "proc";
          };
          "/proc/sys/fs/binfmt_misc" = {
            depends = [ "/proc" ];
            device = "binfmt_misc";
            fsType = "binfmt_misc";
          };
        } // lib.listToAttrs (
          map
            (distro: lib.nameValuePair
              ("/drv/" + distro)
              { label = distro; fsType = "ext4"; options = [ "defaults" "noauto" ]; }
            ) [ "Arch" "Ubuntu" ]
        );

        # networking.dhcpcd.enable = false;

        users.users = {
          ${config.nzbr.user} = {
            uid = 1000;
          };
        };

        i18n.supportedLocales = [
          "en_US.UTF-8/UTF-8"
        ];

        nzbr.home.users = [ config.nzbr.user ];

      }
    );
}
