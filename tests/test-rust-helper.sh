#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/native/ubs-helper/Cargo.toml"
HELPER_SUFFIX=""
[ "${OS:-}" = "Windows_NT" ] && HELPER_SUFFIX=".exe"
HELPER="$ROOT/native/ubs-helper/target/release/ubs-helper$HELPER_SUFFIX"
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

printf '%s\n' 'version 3.1.0' \
  'file ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad abc.txt' \
  > "$FIXTURE/manifest.txt"
[ -z "$("$HELPER" changed-manifest "$FIXTURE/manifest.txt" "$FIXTURE")" ] || {
  echo "Rust batch 비교가 동일 파일을 변경으로 판단했습니다." >&2
  exit 1
}
"$HELPER" verify-manifest "$FIXTURE/manifest.txt" "$FIXTURE" abc.txt
printf 'changed' > "$FIXTURE/abc.txt"
[ "$("$HELPER" changed-manifest "$FIXTURE/manifest.txt" "$FIXTURE")" = 'abc.txt' ] || {
  echo "Rust batch 비교가 변경 파일을 찾지 못했습니다." >&2
  exit 1
}
if "$HELPER" verify-manifest "$FIXTURE/manifest.txt" "$FIXTURE" abc.txt >/dev/null 2>&1; then
  echo "Rust batch 검증이 변경된 파일을 허용했습니다." >&2
  exit 1
fi
printf 'abc' > "$FIXTURE/abc.txt"

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

# 전체 transactional updater도 Rust batch 비교·검증 경로로 통과해야 한다.
UBS_RUST_HELPER="$HELPER" UBS_TEST_LEGACY_RUST_HELPER=true \
  bash "$ROOT/tests/test-update.sh" >/dev/null

echo "Rust helper 테스트 통과"
