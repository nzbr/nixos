# based upon https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/system/boot/loader/raspberrypi/raspberrypi.nix

# TODO: incorporate https://github.com/NixOS/nixos-hardware/tree/master/raspberry-pi

{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  options.nzbr.boot.raspberrypi = with types; {
    enable = mkEnableOption "raspberrypi bootloader/firmware builder";
    initrd = mkEnableOption "boot using an initial ramdisk";
    uefi = mkEnableOption "UEFI firmware";
    config = mkOption {
      type = lazyAttrsOf (
        lazyAttrsOf (
          oneOf [
            int
            str
            (listOf (oneOf [ int str ]))
          ]
        )
      );
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
        # ${import "${inputs.nixpkgs}/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix" {inherit pkgs configTxt;}} -d "$PWD" -c ${default}
        default:
        ''
          cp -r ${pkgs.raspberrypifw}/share/raspberrypi/boot/. "$PWD"
          cp ${configTxt} "$PWD"/config.txt
          echo " init=${default}/init" | cat ${cmdlineTxt} - > "$PWD"/cmdline.txt
          cp ${default}/kernel "$PWD"/nixos-kernel.img
          ${optionalString cfg.initrd ''
            cp ${default}/initrd "$PWD"/nixos-initrd.img
            ${pkgs.gnused}/bin/sed -i 's|^initramfs=|initramfs |' "$PWD"/config.txt
          ''}

          ${cfg.extraFirmwareCommands}
        '';
    in
    mkIf cfg.enable {

      nzbr = {
        boot = {
          disableInitrd = !cfg.initrd;

          raspberrypi.config = {
            all = {
              arm_64bit = mkIf (config.nzbr.system == "aarch64-linux") 1;
              kernel = "nixos-kernel.img";
              disable_overscan = 1;
              # disable_fw_kms_setup = 1;
              camera_auto_detect = 1;
              display_auto_detect = 1;
              max_framebuffers = 2;
              dtoverlay = [
                "vc4-kms-v3d"
              ];
              dtparam = [
                "audio=on"
              ];
            } // (optionalAttrs cfg.initrd {
              initramfs = "nixos-initrd.img followkernel";
            });

            cm4 = {
              otg_mode = 1;
            };

            pi4 = {
              arm_boost = 1;
            };
          };
        };

        installer.sdcard = {
          firmwareSize = 512;
          populateFirmwareCommands = firmwareCommands config.system.build.toplevel;
        };
      };

      nixpkgs.config.platform = mkDefault lib.systems.platforms.raspberrypi4;

      boot = {
        loader = {
          grub.enable = false;
        };

        consoleLogLevel = lib.mkDefault 7;
        kernelParams = [
          "console=serial0,115200"
          "console=tty1"
          (
            if config.nzbr.installer.sdcard.enable
            then "root=PARTUUID=${removePrefix "0x" config.nzbr.installer.sdcard.firmwarePartitionID}-02"
            else
              if hasPrefix "/dev/disk/by-partuuid/" config.fileSystems."/".device
              then "root=PARTUUID=${removePrefix "/dev/disk/by-partuuid/" config.fileSystems."/".device}"
              else
                if hasPrefix "/dev/disk/by-label" config.fileSystems."/".device
                then "root=LABEL=${removePrefix "/dev/disk/by-label/" config.fileSystems."/".device}"
                else "root=${config.fileSystems."/".device}"
          )
          "rootfstype=${config.fileSystems."/".fsType}"
          "rootwait"
          "net.ifnames=0"
          "plymouth.ignore-serial-consoles"
        ];
        # kernelPackages = mkDefault pkgs.linuxKernel.rpiPackages.linux_rpi4;
        # kernelPatches = [
        #   kernelPatches.tuntap
        #   kernelPatches.logo
        # ];
      };

      system.boot.loader.id = "raspberrypi-nzbr";
      system.boot.loader.kernelFile = pkgs.stdenv.hostPlatform.linux-kernel.target;
      system.build.installBootLoader = pkgs.writeShellScript "install-boot-loader.sh" ''
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

      nix.gc.automatic = false; # Reduce writes to the sd card
      networking.interfaces.eth0.useDHCP = mkDefault true;

      environment.systemPackages = with pkgs; [
        libraspberrypi
        raspberrypi-eeprom
      ];

    };
}
