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
        homeOverlay = {
          ".vscode-server" = true;
          ".yarnrc" = false;
          ".nix-defexpr" = true;
        };
      in
      {
        wsl = {
          enable = true;
          inherit (cfg) automountPath;
          automountOptions = "metadata,uid=1000,gid=100";
          defaultUser = config.nzbr.user;
          startMenuLaunchers = true;
          docker-native.enable = mkDefault true;

          # interop.register = mkDefault false;

          wslConf = {
            automount.mountFsTab = mkForce false; # TODO: should be part of NixOS-WSL
            network.generateResolvConf = false;
          };
        };

        nzbr.pattern.common.enable = true;
        nzbr.desktop.gnome.enable = true;

        nzbr.cli.git.enable = mkForce false; # Don't break windows git

        services.xserver.displayManager.gdm.enable = lib.mkForce false;
        services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
        networking.networkmanager.enable = lib.mkForce false;

        environment = {
          systemPackages = with pkgs; [
            chromium
            virt-manager
            wslu
          ];

          variables = {
            # Theme config
            # QT_QPA_PLATFORMTHEME = "gtk2"; # already set somewhere else?
            XDG_CURRENT_DESKTOP = "gnome";
          };

          etc = {
            "resolv.conf".text = ''
              search nzbr.github.beta.tailscale.net nzbr.de
              nameserver 100.100.100.100
              nameserver 1.1.1.1
            '';
          };
        };

        system.activationScripts = {
          wsl-cleanup.text = ''
            for x in $(${pkgs.findutils}/bin/find / -maxdepth 1 -name 'wsl*'); do
              rmdir $x || true
            done
          '';
          setupHome =
            let
              home = config.users.users.${config.nzbr.user}.home;
            in
            stringAfter [ ] ''
              rmdir ${home} || true
              ln -sfT /drv/c/Users/nzbr ${home}
            '';
          copy-dotfiles.deps = mkForce [ "etc" "setupHome" ];
          channels.deps = [ "setupHome" ];
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

        # X410 support on :1
        systemd.services.x410 = {
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.socat}/bin/socat -b65536 UNIX-LISTEN:/tmp/.X11-unix/X1,fork,mode=777 VSOCK-CONNECT:2:6000
          '';
        };
        environment.variables.DISPLAY = ":1";

      }
    );
}
