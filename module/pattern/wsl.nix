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
    mkIf cfg.enable (
      let
        homeOverlay = {
          ".cache" = true;
          ".nix-defexpr" = true;
          ".npm" = true;
          ".pulumi" = true;
          ".vscode-server" = true;
          ".yarnrc" = false;
        };
        automountPath = "/drv/";
      in
      {
        wsl = {
          enable = true;
          defaultUser = config.nzbr.user;
          startMenuLaunchers = true;
          docker-native.enable = mkDefault true;

          # interop.register = mkDefault false;

          wslConf = {
            automount.root = automountPath;
            network.generateResolvConf = false;
          };
        };

        nzbr.pattern.common.enable = true;
        nzbr.desktop.gnome.enable = true;

        nzbr.cli.git.enable = mkForce false; # Don't break windows git

        services.xserver.displayManager.gdm.enable = lib.mkForce false;
        services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
        networking.networkmanager.enable = lib.mkForce false;

        virtualisation.docker.enable = mkOverride 900 false;

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
              search tail9865f.ts.net nzbr.de
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
            stringAfter [ ] ''
              rmdir /home/nzbr || true
              # mkdir -p /home/nzbr && chown nzbr:users /home/nzbr
              # umount /home/nzbr || true
              # mkdir -p /home/.nzbr && chown nzbr:users /home/.nzbr
              # mount -o bind ${automountPath}c/Users/nzbr /home/nzbr
              ln -sfT /drv/c/Users/nzbr /home/nzbr
              ${concatStringsSep "\n" (mapAttrsToList (name: dir: "${if dir then "mkdir -p" else "touch"} /home/.nzbr/${name} && chown nzbr:users /home/.nzbr/${name}") homeOverlay)}
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
        ) // (mapAttrs'
          (path: dir: lib.nameValuePair
            "/home/nzbr/${path}"
            { device = "/home/.nzbr/${path}"; options = [ "bind" ]; }
          )
          homeOverlay
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

        environment.windowsPackages = with pkgs; [
          file
          nix
        ];

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
                              { stdenv, rustc, writeText, windows, ... }: stdenv.mkDerivation {
                                name = "${exe}.exe";

                                nativeBuildInputs = [ rustc ];
                                buildInputs = [ windows.mingw_w64_pthreads ];

                                src = writeText "${exe}.rs" ''
                                  use std::process::Command;

                                  fn main() {
                                    std::process::exit(
                                      real_main()
                                    );
                                  }

                                  fn wslpath(path: String) -> String {
                                    if path.contains("/")
                                    || path.contains("*")
                                    || path.contains("?")
                                    || path.contains("|")
                                    || path.contains("<")
                                    || path.contains(">")
                                    || (!path.contains("\\"))
                                    {
                                      return path;
                                    }

                                    let mut path = path.replace("\\", "/");

                                    if path.len() >= 3 && &path[1..3] == ":/" {
                                      let drive = &path[0..1].to_lowercase();
                                      path = (&path[3..]).to_string();
                                      path = format!("${config.wsl.wslConf.automount.root}{}/{}", drive, path);
                                    }

                                    return path;
                                  }

                                  fn real_main() -> i32 {
                                    let mut process = Command::new("wsl.exe");

                                    process.arg("${drv}/bin/${exe}");

                                    for arg in std::env::args().skip(1).map(wslpath) {
                                      process.arg(arg);
                                    }

                                    let status = process
                                      .status()
                                      .expect("Failed to run ${drv}/bin/${exe}");

                                    match status.code() {
                                      Some(code) => return code,
                                      None       => return -1
                                    }
                                  }
                                '';

                                buildCommand = ''
                                  rustc --target="x86_64-pc-windows-gnu" -C linker=$CC $src -o $out
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
          mkdir -p ${config.wsl.wslConf.automount.root}.wsl-wrappers;
          ${pkgs.rsync}/bin/rsync -avr --delete ${config.system.build.winBin}/. ${config.wsl.wslConf.automount.root}c/.wsl-wrappers/;
        '';
      }
    );
}
