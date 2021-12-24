{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.installer.sdcard.aarch64 = with types; {
    enable = mkEnableOption "aarch64 sdcard preset";
    configTxt = mkOption {
      type = attrsOf (attrsOf anything);
    };
    extraFirmwareCommands = mkStrOpt "";
  };

  config =
    let
      cfg = config.nzbr.installer.sdcard.aarch64;
    in
    {
      boot.loader.grub.enable = false;
      boot.loader.generic-extlinux-compatible.enable = true;

      boot.consoleLogLevel = lib.mkDefault 7;

      # The serial ports listed here are:
      # - ttyS0: for Tegra (Jetson TX1)
      # - ttyAMA0: for QEMU's -machine virt
      boot.kernelParams = [ "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0" ];

      nzbr.installer.sdcard.aarch64.configTxt = {
        pi3.kernel = "u-boot-rpi3.bin";

        pi4 = {
          kernel = "u-boot-rpi4.bin";
          enable_gic = 1;
          armstub = "armstub8-gic.bin";
          disable_overscan = 1;
        };

        all = {
          arm_64bit = 1;
          enable_uart = 1;
        };
      };

      nzbr.installer.sdcard = {
        populateFirmwareCommands =
          let
            configTxt = pkgs.writeText "config.txt" (
              generators.toINI { } config.nzbr.installer.sdcard.aarch64.configTxt
            );
          in
          ''
            (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $out/firmware/)

            # Add the config
            cp ${configTxt} firmware/config.txt

            # Add pi3 specific files
            cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin

            # Add pi4 specific files
            cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
            cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/

          '' + cfg.extraFirmwareCommands;
        populateRootCommands = ''
          mkdir -p ./files/boot
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
        '';
      };
    };
}
