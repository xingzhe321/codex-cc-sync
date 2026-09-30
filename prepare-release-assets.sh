#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PET_ROOT="$(cd -- "$SCRIPT_DIR/../../cc-pet" && pwd)"
OUT_DIR="${1:-}"

if [[ -z "$OUT_DIR" ]]; then
  echo "用法：$SCRIPT_DIR/prepare-release-assets.sh /path/to/release-assets" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp "$THEME_ROOT/app.asar.cc-skin-v24-client-26.928" "$OUT_DIR/app.asar.cc-skin-v24-client-26.928"
cp "$PET_ROOT/pet.json" "$OUT_DIR/pet-c-c.json"
cp "$PET_ROOT/spritesheet.webp" "$OUT_DIR/pet-c-c-spritesheet.webp"

echo "Release 资产已准备：$OUT_DIR"
sha256sum "$OUT_DIR/app.asar.cc-skin-v24-client-26.928"
stat -c 'bytes=%s %n' "$OUT_DIR/app.asar.cc-skin-v24-client-26.928"
