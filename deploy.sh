#!/usr/bin/env bash
set -euxo pipefail

if [ "$1" == "--remote" ]; then
    nixos-rebuild switch --upgrade
    # nix-store --optimize
    # nix-collect-garbage
    exit 0
fi

rsync -avr --progress --delete --exclude ".git" . root@$1:/etc/nixos/config
ssh root@$1 -- bash /etc/nixos/config/deploy.sh --remote