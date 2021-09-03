#!/usr/bin/env bash

FILE="${1%.age}"

if [ -e "$FILE" ]; then
    echo output file exists, aborting
    exit 1
fi

set -euxo pipefail
rage -i ~/.ssh/id_ed25519 -o "$FILE" -d "${1}"
rm "${1}"
