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
      config = attr: "$(nix-instantiate --eval -E \"(builtins.getFlake (toString ./.)).packages.x86_64-linux.nixosConfigurations.$host.config.nzbr.deployment.${attr}\" | tr -d \\\")";
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
      OUT="$(nix build --no-link --json -v $BUILD)"

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
        ${pkgs.nixUnstable}/bin/nix copy $SUBSTITUTE --to ssh://''${USER}@''${HOST} "''${STOREPATH}" -v

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

  enrage =
    let
      nixInstantiate = "${pkgs.nixUnstable}/bin/nix-instantiate";
      sedBin = "${pkgs.gnused}/bin/sed";
      ageBin = "${pkgs.rage}/bin/rage";
    in
    ''
      #!${pkgs.bash}/bin/bash
      # This file contains code from https://github.com/ryantm/agenix/blob/master/pkgs/agenix.nix

      for input in "$@"; do
          if ! [ -f "$input" ]; then
              echo input file \"$input\" does not exist
              exit 1
          fi

          if [ -e "''${input}.age" ]; then
              echo output file \"''${input}.age\" already exists, aborting
              exit 1
          fi
      done

      set -euxo pipefail


      RULES=''${RULES:-./secrets.nix}

      for input in "$@"; do
          FILE="''${input}.age"

          KEYS=$((${nixInstantiate} --eval -E "(let rules = import $RULES; in builtins.concatStringsSep \"\n\" rules.\"$FILE\".publicKeys)" | ${sedBin} 's/"//g' | ${sedBin} 's/\\n/\n/g') || exit 1)

          if [ -z "$KEYS" ]
          then
              >&2 echo "There is no rule for $FILE in $RULES."
              exit 1
          fi

          ENCRYPT=()
          while IFS= read -r key
          do
              ENCRYPT+=(--recipient "$key")
          done <<< "$KEYS"

          ${ageBin} "''${ENCRYPT[@]}" -o "''${FILE}" < "''${input}"
          rm "$input"
      done
    '';

  unrage =
    let
      ageBin = "${pkgs.rage}/bin/rage";
    in
    ''
      #!${pkgs.bash}/bin/bash
      FILE="''${1%.age}"

      if [ -e "$FILE" ]; then
          echo output file exists, aborting
          exit 1
      fi

      set -euxo pipefail
      ${ageBin} -i ~/.ssh/id_ed25519 -o "$FILE" -d "$1"
      rm "$1"
    '';

  mkiso = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    subconfig=""
    if [ -n "''${1:-}" ]; then
      subconfig=".$1"
    fi

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.live''${subconfig}.config.system.build.isoImage" -v
  '';

  toplevel = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.''${1}.config.system.build.toplevel" -v
  '';

  vm = ''
    #!${pkgs.bash}/bin/bash
    set -euxo pipefail

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build ".#nixosConfigurations.''${1}.config.system.build.vm" -v

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
      ${pkgs.writeShellScript "enrage" enrage} "$NOEXT"
    fi
    ${pkgs.agenix}/bin/agenix -e "$FILE"
  '';
}
