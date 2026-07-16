#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/target" "$FIXTURE/symlink-target" "$FIXTURE/flutter-link" \
  "$FIXTURE/incomplete-remote/scripts" "$FIXTURE/incomplete-target"

run_installer() {
  local target="$1"
  shift
  UBS_INSTALL_BASE_URL="file://$ROOT/" UBS_INSTALL_ALLOW_FILE=true \
    "$@" bash -c 'cd "$1" && bash "$2"' _ "$target" "$ROOT/install.sh"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'
  fi
}

run_installer "$FIXTURE/target" >/dev/null

# Manifest 24개와 설치 목록이 완전히 일치해야 한다.
while IFS=' ' read -r kind hash relative extra; do
  [ "$kind" = file ] || continue
  [ -f "$FIXTURE/target/$relative" ] || {
    echo "설치 관리 파일 누락: $relative" >&2
    exit 1
  }
done < "$ROOT/scripts/update-manifest.txt"
[ "$(awk '$1 == "file" { count++ } END { print count + 0 }' "$ROOT/scripts/update-manifest.txt")" -eq 24 ]

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

# 재실행은 기존 파일과 gitignore 블록을 중복 변경하지 않는다.
BEFORE_HASH="$(sha256_file "$FIXTURE/target/scripts/ubs.py")"
run_installer "$FIXTURE/target" >/dev/null
[ "$(grep -Fxc '# BEGIN Universal Build Script' "$FIXTURE/target/.gitignore")" -eq 1 ]
[ "$(sha256_file "$FIXTURE/target/scripts/ubs.py")" = "$BEFORE_HASH" ]

# UBS_FORCE는 drift를 manifest 검증본으로 복원한다.
printf '\n# drift\n' >> "$FIXTURE/target/scripts/ubs.py"
UBS_INSTALL_BASE_URL="file://$ROOT/" UBS_INSTALL_ALLOW_FILE=true UBS_FORCE=true \
  bash -c 'cd "$1" && bash "$2"' _ "$FIXTURE/target" "$ROOT/install.sh" >/dev/null
cmp "$FIXTURE/target/scripts/ubs.py" "$ROOT/scripts/ubs.py"

# 관리 파일의 dangling symlink는 프로젝트 밖으로 쓰지 않고 전체 설치 전 중단한다.
ln -s "$FIXTURE/outside-build.sh" "$FIXTURE/symlink-target/build.sh"
if run_installer "$FIXTURE/symlink-target" >/dev/null 2>&1; then
  echo "설치기가 심볼릭 링크 대상 경로를 허용했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/outside-build.sh" ] || {
  echo "설치기가 프로젝트 밖 파일을 생성했습니다." >&2
  exit 1
}
[ ! -e "$FIXTURE/symlink-target/VERSION" ] || {
  echo "링크 검증 실패 전에 부분 설치가 발생했습니다." >&2
  exit 1
}

# Flutter 보조 파일도 동일한 no-follow 정책을 사용한다.
printf '%s\n' 'name: fixture' 'dependencies:' '  flutter:' '    sdk: flutter' \
  > "$FIXTURE/flutter-link/pubspec.yaml"
ln -s "$FIXTURE/outside-env-example" "$FIXTURE/flutter-link/.env.example"
if run_installer "$FIXTURE/flutter-link" >/dev/null 2>&1; then
  echo "Flutter 보조 파일 심볼릭 링크를 허용했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/outside-env-example" ] || {
  echo "Flutter 보조 파일이 프로젝트 밖에 생성됐습니다." >&2
  exit 1
}
[ ! -e "$FIXTURE/flutter-link/VERSION" ] || {
  echo "보조 파일 검증 실패 전에 부분 설치가 발생했습니다." >&2
  exit 1
}

# 모든 다운로드가 끝나기 전에 실패하면 대상에는 관리 파일을 하나도 적용하지 않는다.
cp "$ROOT/scripts/update-manifest.txt" "$FIXTURE/incomplete-remote/scripts/update-manifest.txt"
while IFS=' ' read -r kind hash relative extra; do
  [ "$kind" = file ] || continue
  mkdir -p "$FIXTURE/incomplete-remote/$(dirname "$relative")"
  cp "$ROOT/$relative" "$FIXTURE/incomplete-remote/$relative"
done < "$ROOT/scripts/update-manifest.txt"
rm -f "$FIXTURE/incomplete-remote/scripts/build-node.sh"
if UBS_INSTALL_BASE_URL="file://$FIXTURE/incomplete-remote/" UBS_INSTALL_ALLOW_FILE=true \
  bash -c 'cd "$1" && bash "$2"' _ "$FIXTURE/incomplete-target" "$ROOT/install.sh" >/dev/null 2>&1; then
  echo "불완전한 release bundle 설치가 성공했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/incomplete-target/VERSION" ] || {
  echo "다운로드 실패 후 부분 설치 파일이 남았습니다." >&2
  exit 1
}

echo "설치기 manifest staging·rollback·개인정보 ignore·링크 방어 테스트 통과"
