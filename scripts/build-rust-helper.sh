#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/i18n.sh"
MANIFEST="$ROOT/native/ubs-helper/Cargo.toml"
OUTPUT_DIR="$ROOT/.ubs/bin"
BUILD_DIR="${UBS_RUST_BUILD_TARGET_DIR:-$ROOT/.ubs/cargo-target}"
EXE_SUFFIX=""
[ "${OS:-}" = "Windows_NT" ] && EXE_SUFFIX=".exe"

command -v cargo >/dev/null 2>&1 || {
  echo "$(ubs_msg RUST_HELPER_NEED_CARGO)" >&2
  exit 1
}

for path in "$ROOT/.ubs" "$OUTPUT_DIR" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX" "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX.sha256"; do
  [ ! -L "$path" ] || { echo "$(ubs_msg RUST_HELPER_SYMLINK_PATH "$path")" >&2; exit 1; }
done

HOST_TRIPLE="$(rustc -vV | sed -n 's/^host: //p')"
[ -n "$HOST_TRIPLE" ] || { echo "$(ubs_msg RUST_HELPER_HOST_TARGET_UNKNOWN)" >&2; exit 1; }
CARGO_TARGET_DIR="$BUILD_DIR" cargo build --release --locked --target "$HOST_TRIPLE" --manifest-path "$MANIFEST"
SOURCE="$BUILD_DIR/$HOST_TRIPLE/release/ubs-helper$EXE_SUFFIX"
[ -f "$SOURCE" ] || { echo "$(ubs_msg RUST_HELPER_ARTIFACT_NOT_FOUND "$SOURCE")" >&2; exit 1; }
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
echo "$(ubs_msg RUST_HELPER_INSTALL_DONE "$OUTPUT_DIR/ubs-helper$EXE_SUFFIX")"
