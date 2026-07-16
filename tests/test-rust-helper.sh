#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/native/ubs-helper/Cargo.toml"
HELPER="$ROOT/native/ubs-helper/target/release/ubs-helper"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

cargo test --locked --manifest-path "$MANIFEST"
cargo build --release --locked --manifest-path "$MANIFEST"

printf 'abc' > "$FIXTURE/abc.txt"
[ "$("$HELPER" sha256 "$FIXTURE/abc.txt")" = \
  "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" ] || {
  echo "Rust SHA-256 결과가 표준 벡터와 다릅니다." >&2
  exit 1
}
"$HELPER" verify-sha256 "$FIXTURE/abc.txt" \
  "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
"$HELPER" validate-relative "scripts/ubs.py"
if "$HELPER" validate-relative "../escape" >/dev/null 2>&1; then
  echo "Rust helper가 상위 경로 탈출을 허용했습니다." >&2
  exit 1
fi

# Shell updater가 도구 존재 시 Rust 구현을 실제로 우선 사용해야 한다.
# shellcheck source=../scripts/lib/update.sh
source "$ROOT/scripts/lib/update.sh"
UBS_RUST_HELPER="$HELPER"
export UBS_RUST_HELPER
[ "$(ubs_update_sha256 "$FIXTURE/abc.txt")" = \
  "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" ] || {
  echo "업데이트 모듈이 Rust SHA-256 helper를 사용하지 못했습니다." >&2
  exit 1
}
ubs_update_safe_destination "$ROOT" "scripts/ubs.py"

echo "Rust helper 테스트 통과"
