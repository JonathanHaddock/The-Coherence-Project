#!/bin/sh
# Download every dataset listed in data/manifests/*.txt into data/raw/.
# Files already present are skipped; run `origin dataset` afterwards to verify them.
set -eu
cd "$(dirname "$0")/.."
mkdir -p data/raw

for manifest in data/manifests/*.txt; do
    grep -v '^#' "$manifest" | while read -r name size checksum url; do
        [ -z "$name" ] && continue
        if [ -f "data/raw/$name" ]; then
            echo "skip      $name (already downloaded)"
            continue
        fi
        echo "download  $name ($size bytes)"
        curl -fsSL "$url" -o "data/raw/$name.part"
        mv "data/raw/$name.part" "data/raw/$name"
    done
done
