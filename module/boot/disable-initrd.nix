{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {
  options.nzbr.boot.disableInitrd = mkEnableOption "Create a fake initramfs";

  config = mkIf config.nzbr.boot.disableInitrd {
    boot.initrd.enable = false;

    system.build.initialRamdisk = pkgs.runCommand "fake-initrd" { } ''
      mkdir -p $out
      touch $out/initrd
      ${pkgs.zstd}/bin/zstd $out/initrd
    '';
    system.build.initialRamdiskSecretAppender = pkgs.writeShellScriptBin "append-initrd-secrets" "";
  };
}
