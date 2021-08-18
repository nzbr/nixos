#!/usr/bin/env bash
set -euxo pipefail

nix build '.#nixosConfigurations.live.config.system.build.isoImage' -v
rsync --info=progress2 result/iso/*.iso .
