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
  deploy =
    let
      config = attr: "$(nix-instantiate --eval -E \"(builtins.getFlake (toString ./.)).nixosConfigurations.$host.config.nzbr.deployment.${attr}\" | tr -d \\\")";
      getOutputByNum = "${pkgs.python3}/bin/python3 -c 'import sys; import json; print(json.loads(sys.argv[2])[int(sys.argv[1])][\"outputs\"][\"out\"])'";
    in
    ''
      #!${pkgs.bash}/bin/bash
      IFS=$',' # Split on , instead of whitespace

      ${checkflake}

      if [ -z "''${1:-}" ]; then
        echo "No target specified"
        exit 1
      fi
      if [ -z "''${2:-}" ]; then
        echo "No action specified"
        exit 1
      fi

      set -euxo pipefail

      BUILD=""
      for host in $1; do
        BUILD="$BUILD,.#nixosConfigurations.''${host}.config.system.build.toplevel"
      done
      BUILD=''${BUILD:1}

      # Build
      OUT="$(nix build --no-link --json -vL $BUILD)"

      # Copy
      NUM=0
      for host in $1; do
        STOREPATH=$(${getOutputByNum} ''${NUM} "$OUT")
        if ${config "substituteOnDestination"}; then
          SUBSTITUTE="-s"
        else
          SUBSTITUTE=""
        fi
        USER=${config "targetUser"}
        HOST=${config "targetHost"}
        ${pkgs.nixUnstable}/bin/nix copy $SUBSTITUTE --to ssh://''${USER}@''${HOST} "''${STOREPATH}" -vL

        # Activate
        ssh -t ''${USER}@''${HOST} -- ''${STOREPATH}/bin/switch-to-configuration $2

        NUM=$(( NUM + 1 ))
      done
    '';

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
    ${pkgs.agenix}/bin/agenix -e "$FILE"
  '';
}
