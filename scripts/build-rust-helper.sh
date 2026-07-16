#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/native/ubs-helper/Cargo.toml"
OUTPUT_DIR="$ROOT/.ubs/bin"

command -v cargo >/dev/null 2>&1 || {
  echo "Rust helper 빌드에는 cargo가 필요합니다." >&2
  exit 1
}

cargo build --release --locked --manifest-path "$MANIFEST"
mkdir -p "$OUTPUT_DIR"
cp "$ROOT/native/ubs-helper/target/release/ubs-helper" "$OUTPUT_DIR/ubs-helper"
chmod 755 "$OUTPUT_DIR/ubs-helper"
echo "Rust helper 설치 완료: $OUTPUT_DIR/ubs-helper"
