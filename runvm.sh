#!/usr/bin/env bash
set -euxo pipefail

nix build ".#nixosConfigurations.${1}.config.system.build.vm" -v

mkdir -p /tmp/nixvm
if [ -f /tmp/nixvm/hostname ]; then
	if [ "${2:-}" == "-c" ] || ! [ "$(cat /tmp/nixvm/hostname)" == "$1" ]; then
		rm -f /tmp/nixvm/root.qcow2
	fi
fi
printf $1 >/tmp/nixvm/hostname

export QEMU_OPTS="-m 4096 -vga qxl ${QEMU_OPTS:-}"
export NIX_DISK_IMAGE=/tmp/nixvm/root.qcow2
result/bin/run-live-vm
