{ config, lib, inputs, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options = with types; {
    nzbr.pattern.wsl = {
      enable = mkEnableOption "Windows Subsystem for Linux guest";
    };

    environment.windowsPackages = mkOption {
      type = listOf package;
      default = [ ];
    };
  };

  config =
    let
      cfg = config.nzbr.pattern.wsl;
    in
    mkIf cfg.enable {
      wsl = {
        enable = true;
        defaultUser = config.nzbr.user;
        startMenuLaunchers = true;
        # docker-native.enable = mkDefault true;
        # docker-native.addToDockerGroup = true;

        # nativeSystemd = true;

        # interop.register = mkDefault false;

        wslConf.automount.root = "/drv";
      };

      nzbr.pattern.common.enable = true;
      nzbr.desktop.gnome.enable = true;

      services.xserver.displayManager.gdm.enable = lib.mkForce false;
      services.xserver.displayManager.autoLogin.enable = lib.mkForce false;

      networking.networkmanager.enable = lib.mkForce false;

      environment = {
        systemPackages = with pkgs; [
          firefox
          virt-manager
          wslu
          wsl-open
          xdg-utils
        ];

        variables = {
          # Theme config
          # QT_QPA_PLATFORMTHEME = "gtk2"; # already set somewhere else?
          XDG_CURRENT_DESKTOP = "gnome";

          QT_QPA_PLATFORM = "wayland;xcb";
          SDL_VIDEODRIVER = "wayland";
          NIXOS_OZONE_WL = "1"; # chromium
        };
      };

      system.activationScripts = {
        wsl-cleanup.text = ''
          for x in $(${pkgs.findutils}/bin/find / -maxdepth 1 -name 'wsl*'); do
            rmdir $x || true
          done
        '';
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

      users.users = {
        ${config.nzbr.user} = {
          uid = 1000;
        };
      };

      nzbr.home.users = [ config.nzbr.user ];

      # X410 support on :1
      systemd.services.x410 = {
        wantedBy = [ "multi-user.target" ];
        script = ''
          ${pkgs.socat}/bin/socat -b65536 UNIX-LISTEN:/tmp/.X11-unix/X1,fork,mode=777 VSOCK-CONNECT:2:6000
        '';
      };
      environment.variables.DISPLAY = ":1";

      environment.windowsPackages = with pkgs; [
        file
        nix
        nixpkgs-fmt
      ];

      services.udev.enable = lib.mkDefault false;
      hardware.firmware = mkOverride 60 [ ];

      system.build.winBin =
        pkgs.runCommand "windows-path" { } (concatStringsSep "\n"
          (
            [ "mkdir -p $out" ]
            ++
            (flatten
              (map
                (drv:
                  map
                    (exe:
                      let
                        bin = pkgs.pkgsCross.mingwW64.callPackage
                          (
                            { stdenv, writeText, substituteAll, ... }: stdenv.mkDerivation {
                              name = "${exe}.exe";

                              src = substituteAll {
                                name = "${exe}.cpp";
                                src = ./winBin.cpp;

                                inherit drv exe;
                                automountRoot = config.wsl.wslConf.automount.root;
                              };

                              buildCommand = ''
                                cp $src ${exe}.cpp
                                $CXX -o $out ${exe}.cpp
                              '';
                            }
                          )
                          { };
                      in
                      "cp ${bin} $out/${exe}.exe"
                    )
                    (
                      if (readDir drv) ? "bin"
                      then (attrNames (readDir "${drv}/bin"))
                      else [ ]
                    )
                )
                config.environment.windowsPackages
              )
            )
          )
        );

      system.activationScripts.windows-path = stringAfter [ ] ''
        mkdir -p ${config.wsl.wslConf.automount.root}/.wsl-wrappers;
        ${pkgs.rsync}/bin/rsync -avr --delete ${config.system.build.winBin}/. ${config.wsl.wslConf.automount.root}/c/.wsl-wrappers/;
      '';
    };
}
