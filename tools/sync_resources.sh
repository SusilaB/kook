#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/App/Kook/Resources"
cp -f "$ROOT"/data/*.json "$ROOT/App/Kook/Resources/"
echo "Synced data/*.json → App/Kook/Resources/"
