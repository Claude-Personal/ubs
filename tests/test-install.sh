#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/bin" "$FIXTURE/target" "$FIXTURE/symlink-target"

printf '%s\n' '#!/usr/bin/env bash' \
  'set -e' \
  'url=""; output=""' \
  'while [ $# -gt 0 ]; do' \
  '  case "$1" in' \
  '    -o) shift; output="$1" ;;' \
  '    http*) url="$1" ;;' \
  '  esac' \
  '  shift' \
  'done' \
  'relative="${url#*main/}"' \
  'cp "$UBS_TEST_REMOTE/$relative" "$output"' \
  > "$FIXTURE/bin/curl"
chmod +x "$FIXTURE/bin/curl"

PATH="$FIXTURE/bin:$PATH" UBS_TEST_REMOTE="$ROOT" \
  bash -c 'cd "$1" && bash "$2"' _ "$FIXTURE/target" "$ROOT/install.sh" >/dev/null

[ -f "$FIXTURE/target/install.sh" ] || { echo "설치기가 자신을 관리 파일로 설치하지 않았습니다." >&2; exit 1; }
[ -f "$FIXTURE/target/scripts/ubs.py" ] || { echo "Python core 설치 실패" >&2; exit 1; }
grep -Fq '# BEGIN Universal Build Script' "$FIXTURE/target/.gitignore" || {
  echo "설치기가 개인정보 보호 ignore 블록을 추가하지 않았습니다." >&2
  exit 1
}
for pattern in '.ubs/' '.env' 'signing/' '*.jks'; do
  grep -Fqx "$pattern" "$FIXTURE/target/.gitignore" || {
    echo "설치 ignore 규칙 누락: $pattern" >&2
    exit 1
  }
done

ln -s "$FIXTURE/outside-build.sh" "$FIXTURE/symlink-target/build.sh"
if PATH="$FIXTURE/bin:$PATH" UBS_TEST_REMOTE="$ROOT" \
  bash -c 'cd "$1" && bash "$2"' _ "$FIXTURE/symlink-target" "$ROOT/install.sh" >/dev/null 2>&1; then
  echo "설치기가 심볼릭 링크 대상 경로를 허용했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/outside-build.sh" ] || {
  echo "설치기가 프로젝트 밖 파일을 생성했습니다." >&2
  exit 1
}

echo "설치기 원자 교체·개인정보 ignore·링크 방어 테스트 통과"
