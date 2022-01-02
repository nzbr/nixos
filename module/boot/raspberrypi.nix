# based upon https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/system/boot/loader/raspberrypi/raspberrypi.nix

{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  options.nzbr.boot.raspberrypi = with types; {
    enable = mkEnableOption "raspberrypi bootloader/firmware builder";
    config = mkOption {
      type = attrsOf (attrsOf anything);
    };
    extraFirmwareCommands = mkStrOpt "";
  };

  config =
    let
      cfg = config.nzbr.boot.raspberrypi;
      firmwareCommands =
        let
          configTxt = pkgs.writeText "config.txt" (
            generators.toINI { listsAsDuplicateKeys = true; } config.nzbr.boot.raspberrypi.config
          );
          cmdlineTxt = pkgs.writeText "cmdline.txt" (
            concatStringsSep " " config.boot.kernelParams
          );
        in
        default:
        ''
          # ${import "${inputs.nixpkgs}/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix" {inherit pkgs configTxt;}} -d "$PWD" -c ${default}
          cp -r ${pkgs.raspberrypifw}/share/raspberrypi/boot/. "$PWD"
          cp ${configTxt} "$PWD"/config.txt
          cp ${cmdlineTxt} "$PWD"/cmdline.txt
          cp ${default}/kernel "$PWD"/nixos-kernel.img

          ${cfg.extraFirmwareCommands}
        '';
    in
    mkIf cfg.enable {

      boot = {
        loader = {
          grub.enable = false;
        };

        consoleLogLevel = lib.mkDefault 7;
        kernelParams = [
          "console=serial0,115200"
          "console=tty1"
          "root=/dev/mmcblk0p2"
          "rootfstype=ext4"
          "rootwait"
          "plymouth.ignore-serial-consoles"
        ];
      };

      nzbr.boot.disableInitrd = true;

      nzbr.boot.raspberrypi.config = {
        all = {
          arm_64bit = mkIf (config.nzbr.system == "aarch64-linux") 1;
          kernel = "nixos-kernel.img";
          disable_overscan = 1;
          camera_auto_detect = 1;
          display_auto_detect = 1;
          dtoverlay = [
            "vc4-kms-v3d"
          ];
        };

        pi4 = {
          arm_boost = 1;
        };
      };

      nzbr.installer.sdcard = {
        firmwareSize = 512;
        populateFirmwareCommands = firmwareCommands config.system.build.toplevel;
        populateRootCommands = ''
          mkdir -p ./files/sbin
          ln -s ${config.system.build.toplevel}/init ./files/sbin/init
        '';
      };

      system.boot.loader.id = "raspberrypi-nzbr";
      system.boot.loader.kernelFile = pkgs.stdenv.hostPlatform.linux-kernel.target;
      system.build.installBootLoader =
        let
          initScriptBuilder = pkgs.substituteAll {
            name = "init-script-builder.sh";
            src = "${inputs.nixpkgs}/nixos/modules/system/boot/loader/init-script/init-script-builder.sh";
            isExecutable = true;
            inherit (pkgs) bash;
            path = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep ];
          };
        in
        pkgs.writeShellScript "install-boot-loader.sh" ''
          echo Creating /sbin/init
          ${initScriptBuilder} "$1"

          echo Building firmware
          cd $(mktemp -d)
          ${firmwareCommands "$1"}

          echo Updating firmware
          if ! mount | grep -q /boot/firmware; then
            mount /boot/firmware
          fi
          mount -o remount,rw /boot/firmware
          rsync --info=progress2 -lr --delete "$PWD"/ /boot/firmware
          mount -o remount,ro /boot/firmware
        '';
    };
}
