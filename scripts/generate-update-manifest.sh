#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/update.sh
source "$ROOT/scripts/lib/update.sh"

version="$(tr -d '[:space:]' < "$ROOT/VERSION")"
[ -n "$version" ] || { echo "VERSION이 비어 있습니다." >&2; exit 1; }

echo "# scripts/generate-update-manifest.sh로 생성합니다. 임의 편집하지 마세요."
echo "version $version"
while IFS= read -r relative; do
  [ -f "$ROOT/$relative" ] || { echo "필수 파일 누락: $relative" >&2; exit 1; }
  printf 'file %s %s\n' "$(ubs_update_sha256 "$ROOT/$relative")" "$relative"
done < <(ubs_update_required_paths)
