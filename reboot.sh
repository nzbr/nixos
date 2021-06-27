#!/usr/bin/env bash
set -euxo pipefail

ssh root@$1 reboot || true
sleep 10s
while ! ssh root@$1 true; do
    sleep 3s
done
ssh root@$1
