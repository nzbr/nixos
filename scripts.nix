{ lib, pkgs, self, ... }:
let
  checkflake = ''
    if ! [ -f flake.nix ]; then
      echo "No flake.nix found in the current directory"
      exit 1
    fi
  '';
in
{
  deploy = ''
    #!${pkgs.bash}/bin/bash

    ${checkflake}

    if [ -z "''${1:-}" ]; then
      echo "No target specified"
      exit 1
    fi

    set -euxo pipefail

    HOST=$(ssh ''${1} -- hostname)
    ${pkgs.nixUnstable}/bin/nix copy -s --to ssh://''${1} ".#nixosConfigurations.''${HOST}.config.system.build.toplevel" -v

    # --exclude ".git"
    ${pkgs.rsync}/bin/rsync -avr --info=progress2 --delete . $1:/etc/nixos/config
    ssh -t $1 -- nixos-rebuild switch --flake /etc/nixos/config -v --show-trace
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

    ${checkflake}

    ${pkgs.nixUnstable}/bin/nix build '.#nixosConfigurations.live.config.system.build.isoImage' -v
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
    ${pkgs.agenix}/bin/agenix -e "$FILE"
  '';
}
