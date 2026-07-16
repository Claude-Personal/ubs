#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
REMOTE="$FIXTURE/remote"
TARGET="$FIXTURE/target"
trap 'rm -rf "$FIXTURE"' EXIT

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

mkdir -p "$REMOTE/scripts" "$TARGET"
cp "$REPO_DIR/scripts/update-manifest.txt" "$REMOTE/scripts/update-manifest.txt"

while IFS=' ' read -r kind hash relative extra; do
  [ "$kind" = "file" ] || continue
  mkdir -p "$REMOTE/$(dirname "$relative")" "$TARGET/$(dirname "$relative")"
  cp "$REPO_DIR/$relative" "$REMOTE/$relative"
  cp "$REPO_DIR/$relative" "$TARGET/$relative"
done < "$REPO_DIR/scripts/update-manifest.txt"

printf '\n# local drift\n' >> "$TARGET/scripts/build-node.sh"
DRIFT_HASH="$(sha256_file "$TARGET/scripts/build-node.sh")"

CHECK_OUTPUT="$(UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check)"
printf '%s\n' "$CHECK_OUTPUT" | grep -Fq '변경 대상: 1개' || {
  echo "update --check가 변경 파일 하나를 감지하지 못했습니다." >&2
  exit 1
}
[ "$(sha256_file "$TARGET/scripts/build-node.sh")" = "$DRIFT_HASH" ] || {
  echo "update --check가 로컬 파일을 변경했습니다." >&2
  exit 1
}

DRY_OUTPUT="$(UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --dry-run)"
printf '%s\n' "$DRY_OUTPUT" | grep -Fq 'dry-run이므로' || {
  echo "update --dry-run 결과가 명확하지 않습니다." >&2
  exit 1
}
[ "$(sha256_file "$TARGET/scripts/build-node.sh")" = "$DRIFT_HASH" ] || {
  echo "update --dry-run이 로컬 파일을 변경했습니다." >&2
  exit 1
}

UPDATE_OUTPUT="$(UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update)"
cmp "$TARGET/scripts/build-node.sh" "$REMOTE/scripts/build-node.sh" || {
  echo "업데이트 파일이 원격 검증본과 다릅니다." >&2
  exit 1
}
BACKUP_DIR="$(printf '%s\n' "$UPDATE_OUTPUT" | sed -n 's/^백업 위치: //p')"
[ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/scripts/build-node.sh" ] || {
  echo "업데이트 백업을 찾을 수 없습니다." >&2
  exit 1
}
grep -Fq '# local drift' "$BACKUP_DIR/scripts/build-node.sh" || {
  echo "백업에 업데이트 전 파일이 보존되지 않았습니다." >&2
  exit 1
}

# 감지 모듈이 사라져도 update 명령은 독립적으로 실행되어 복구해야 한다.
rm -f "$TARGET/scripts/lib/detect.sh"
MISSING_CHECK="$(UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check)"
printf '%s\n' "$MISSING_CHECK" | grep -Fq 'scripts/lib/detect.sh' || {
  echo "update가 누락된 감지 모듈을 찾지 못했습니다." >&2
  exit 1
}
UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update >/dev/null
cmp "$TARGET/scripts/lib/detect.sh" "$REMOTE/scripts/lib/detect.sh" || {
  echo "update가 누락된 감지 모듈을 복구하지 못했습니다." >&2
  exit 1
}

if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --json >/dev/null 2>&1; then
  echo "update가 지원하지 않는 옵션을 허용했습니다." >&2
  exit 1
fi

# 두 파일 중 두 번째 교체가 실패하면 첫 번째 파일도 업데이트 전 상태로 복원해야 한다.
printf '\n# rollback build drift\n' >> "$TARGET/build.sh"
printf '\n# rollback node drift\n' >> "$TARGET/scripts/build-node.sh"
ROLLBACK_BUILD_HASH="$(sha256_file "$TARGET/build.sh")"
ROLLBACK_NODE_HASH="$(sha256_file "$TARGET/scripts/build-node.sh")"
mkdir -p "$FIXTURE/fail-bin"
printf '%s\n' '#!/usr/bin/env bash' \
  'last=""' 'for value in "$@"; do last="$value"; done' \
  'case "$last" in */scripts/build-node.sh) exit 9 ;; esac' \
  'exec /bin/mv "$@"' > "$FIXTURE/fail-bin/mv"
chmod +x "$FIXTURE/fail-bin/mv"
if PATH="$FIXTURE/fail-bin:$PATH" UBS_UPDATE_BASE_URL="file://$REMOTE" \
  UBS_UPDATE_ALLOW_FILE=true bash "$TARGET/build.sh" update >/dev/null 2>&1; then
  echo "교체 실패를 구성한 업데이트가 성공했습니다." >&2
  exit 1
fi
[ "$(sha256_file "$TARGET/build.sh")" = "$ROLLBACK_BUILD_HASH" ] || {
  echo "부분 실패 후 build.sh가 원래 상태로 복원되지 않았습니다." >&2
  exit 1
}
[ "$(sha256_file "$TARGET/scripts/build-node.sh")" = "$ROLLBACK_NODE_HASH" ] || {
  echo "부분 실패 후 build-node.sh 상태가 바뀌었습니다." >&2
  exit 1
}

# 원격 버전이 더 낮으면 명시적 허용 없이 적용하지 않아야 한다.
sed 's/^version 2\.1\.0$/version 2.0.0/' "$REPO_DIR/scripts/update-manifest.txt" \
  > "$REMOTE/scripts/update-manifest.txt"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "다운그레이드 manifest를 허용했습니다." >&2
  exit 1
fi
cp "$REPO_DIR/scripts/update-manifest.txt" "$REMOTE/scripts/update-manifest.txt"

# manifest와 실제 다운로드 파일의 해시가 다르면 백업·교체 전에 중단해야 한다.
printf '\n# tampered remote\n' >> "$REMOTE/scripts/build-node.sh"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update >/dev/null 2>&1; then
  echo "SHA-256이 다른 원격 파일을 허용했습니다." >&2
  exit 1
fi
[ "$(sha256_file "$TARGET/build.sh")" = "$ROLLBACK_BUILD_HASH" ] || {
  echo "해시 검증 실패 전에 로컬 파일이 변경됐습니다." >&2
  exit 1
}
cp "$REPO_DIR/scripts/build-node.sh" "$REMOTE/scripts/build-node.sh"

# 필수 파일 누락과 중복 항목도 manifest 전체를 거부해야 한다.
grep -v ' scripts/build-node.sh$' "$REPO_DIR/scripts/update-manifest.txt" \
  > "$REMOTE/scripts/update-manifest.txt"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "필수 경로가 누락된 manifest를 허용했습니다." >&2
  exit 1
fi
cp "$REPO_DIR/scripts/update-manifest.txt" "$REMOTE/scripts/update-manifest.txt"
grep ' scripts/build-node.sh$' "$REPO_DIR/scripts/update-manifest.txt" \
  >> "$REMOTE/scripts/update-manifest.txt"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "중복 경로가 있는 manifest를 허용했습니다." >&2
  exit 1
fi
cp "$REPO_DIR/scripts/update-manifest.txt" "$REMOTE/scripts/update-manifest.txt"

# 동시 실행 잠금이 있으면 두 번째 실제 업데이트를 거부해야 한다.
mkdir -p "$TARGET/.ubs/update.lock"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update >/dev/null 2>&1; then
  echo "동시에 두 업데이트를 허용했습니다." >&2
  exit 1
fi
rmdir "$TARGET/.ubs/update.lock"

# manifest가 허용 목록 밖으로 쓰려 하면 다운로드 전에 중단해야 한다.
printf '%s\n' 'version 9.9.9' \
  'file 0000000000000000000000000000000000000000000000000000000000000000 ../escape' \
  > "$REMOTE/scripts/update-manifest.txt"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "악성 manifest 상대 경로를 허용했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/escape" ] || { echo "허용 경로 밖 파일이 생성됐습니다." >&2; exit 1; }

# 관리 경로 또는 부모가 심볼릭 링크면 외부 파일을 건드리지 않아야 한다.
cp "$REPO_DIR/scripts/update-manifest.txt" "$REMOTE/scripts/update-manifest.txt"
printf '%s\n' 'outside' > "$FIXTURE/outside"
rm -f "$TARGET/scripts/build-node.sh"
ln -s "$FIXTURE/outside" "$TARGET/scripts/build-node.sh"
if UBS_UPDATE_BASE_URL="file://$REMOTE" UBS_UPDATE_ALLOW_FILE=true \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "심볼릭 링크 관리 경로를 허용했습니다." >&2
  exit 1
fi
grep -Fqx 'outside' "$FIXTURE/outside" || { echo "심볼릭 링크 외부 파일이 변경됐습니다." >&2; exit 1; }

if UBS_UPDATE_BASE_URL="http://example.invalid" \
  bash "$TARGET/build.sh" update --check >/dev/null 2>&1; then
  echo "HTTPS가 아닌 업데이트 URL을 허용했습니다." >&2
  exit 1
fi

echo "업데이트 테스트 통과"
