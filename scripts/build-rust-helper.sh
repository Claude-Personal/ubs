#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/native/ubs-helper/Cargo.toml"
OUTPUT_DIR="$ROOT/.ubs/bin"
BUILD_DIR="${UBS_RUST_BUILD_TARGET_DIR:-$ROOT/.ubs/cargo-target}"
EXE_SUFFIX=""
[ "${OS:-}" = "Windows_NT" ] && EXE_SUFFIX=".exe"

command -v cargo >/dev/null 2>&1 || {
  echo "Rust helper 빌드에는 cargo가 필요합니다." >&2
  exit 1
}

for path in "$ROOT/.ubs" "$OUTPUT_DIR" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX.sha256"; do
  [ ! -L "$path" ] || { echo "Rust helper 경로가 심볼릭 링크입니다: $path" >&2; exit 1; }
done

HOST_TRIPLE="$(rustc -vV | sed -n 's/^host: //p')"
[ -n "$HOST_TRIPLE" ] || { echo "Rust host target을 확인할 수 없습니다." >&2; exit 1; }
CARGO_TARGET_DIR="$BUILD_DIR" cargo build --release --locked --target "$HOST_TRIPLE" --manifest-path "$MANIFEST"
SOURCE="$BUILD_DIR/$HOST_TRIPLE/release/ubs-helper$EXE_SUFFIX"
[ -f "$SOURCE" ] || { echo "Rust helper 산출물을 찾을 수 없습니다: $SOURCE" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"
INSTALL_TMP="$(mktemp "$OUTPUT_DIR/.ubs-helper.XXXXXX")"
CHECKSUM_TMP="$(mktemp "$OUTPUT_DIR/.ubs-helper-checksum.XXXXXX")"
trap 'rm -f "$INSTALL_TMP" "$CHECKSUM_TMP"' EXIT
cp "$SOURCE" "$INSTALL_TMP"
chmod 755 "$INSTALL_TMP"
mv -f "$INSTALL_TMP" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX"
if command -v sha256sum >/dev/null 2>&1; then
  HELPER_SHA="$(sha256sum "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX" | awk '{print $1}')"
else
  HELPER_SHA="$(shasum -a 256 "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX" | awk '{print $1}')"
fi
printf '%s\n' "$HELPER_SHA" > "$CHECKSUM_TMP"
chmod 644 "$CHECKSUM_TMP"
mv -f "$CHECKSUM_TMP" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX.sha256"
trap - EXIT
echo "Rust helper 설치 완료: $OUTPUT_DIR/ubs-helper$EXE_SUFFIX"
