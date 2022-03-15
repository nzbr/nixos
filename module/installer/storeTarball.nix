{ pkgs, config, lib, ... }:
with builtins; with lib;
let
  pkgs2storeContents = l: map (x: { object = x; symlink = "none"; }) l;
  nixpkgs = lib.cleanSource pkgs.path;

  prepareRoot = pkgs.writeShellScript "prepare" ''
    set -euxo pipefail

    mkdir -m 0755 ./etc
    mkdir -m 1777 ./tmp

    # Set system profile
    system=${config.system.build.toplevel}
    ./$system/sw/bin/nix-store --store `pwd` --load-db < ./nix-path-registration
    rm ./nix-path-registration
    ./$system/sw/bin/nix-env --store `pwd` -p ./nix/var/nix/profiles/system --set $system

    # It's now a NixOS!
    touch ./etc/NIXOS
  '';

  installer = pkgs.writeScript "installer" ''
    #!/usr/bin/env bash
    set -eux
    nixos-enter --root $(dirname $0) -- ${pkgs.bash}/bin/bash -c 'NIXOS_INSTALL_BOOTLOADER=1 ${config.system.build.toplevel}/bin/switch-to-configuration boot'
    rm $0
  '';
in
{
  system.build.storeTarball = (pkgs.callPackage "${nixpkgs}/nixos/lib/make-system-tarball.nix" {
    contents = [
      { source = installer; target = "/install.sh"; }
    ];

    fileName = "nixos-${config.system.name}";

    storeContents = pkgs2storeContents [
      config.system.build.toplevel
      pkgs.bash
      installer
    ];

    extraCommands = prepareRoot;

    compressCommand = "${pkgs.zstd}/bin/zstd";
    compressionExtension = ".zst";
  }).overrideAttrs (attrs: {
    preferLocalBuild = true;
  });
}
