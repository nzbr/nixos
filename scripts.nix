{ lib, pkgs, self, ... }:
let
  checkflake = ''
    if ! [ -f flake.nix ]; then
      echo "No flake.nix found in the current directory"
      exit 1
    fi
  '';
in
rec {
  update = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix flake update --commit-lock-file
  '';

  mkiso = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    subconfig=""
    if [ -n "''${1:-}" ]; then
      subconfig=".$1"
    fi

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.live''${subconfig}.config.system.build.isoImage" -vL
  '';

  toplevel = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.''${1}.config.system.build.toplevel" -vL
  '';

  vm = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.''${1}.config.system.build.vm" -vL

    mkdir -p /tmp/nixvm
    if [ -f /tmp/nixvm/hostname ]; then
      if [ "''${2:-}" == "-c" ] || ! [ "$(cat /tmp/nixvm/hostname)" == "$1" ]; then
        rm -f /tmp/nixvm/root.qcow2
      fi
    fi
    printf $1 >/tmp/nixvm/hostname

    export QEMU_OPTS="-m 4096 -vga qxl ''${QEMU_OPTS:-}"
    export NIX_DISK_IMAGE=/tmp/nixvm/root.qcow2
    result/bin/run-live-vm
  '';

  wifiedit = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    FILE="asset/iwd/$(echo -n $1 | sha256sum | awk '{print $1;}').age"
    if ! [ -f "$FILE" ]; then
      NOEXT="''${FILE%.*}"
      touch "$NOEXT"
      enrage "$NOEXT"
    fi
    ${pkgs.ragenix}/bin/agenix -e "$FILE"
  '';
}
