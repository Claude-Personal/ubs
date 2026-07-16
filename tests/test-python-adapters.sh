#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/bin" "$FIXTURE/android/app" "$FIXTURE/android/gradle" \
  "$FIXTURE/mono/apps/child" "$FIXTURE/node"

# Version Catalog plugin alias도 Android application으로 감지하고 bundleRelease를 선택한다.
printf '%s\n' 'pluginManagement {}' > "$FIXTURE/android/settings.gradle.kts"
printf '%s\n' '[plugins]' \
  'android-application = { id = "com.android.application", version = "8.7.0" }' \
  > "$FIXTURE/android/gradle/libs.versions.toml"
printf '%s\n' 'plugins { alias(libs.plugins.android.application) }' \
  'android { namespace = "dev.example" }' > "$FIXTURE/android/app/build.gradle.kts"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >> "$UBS_TEST_LOG"' \
  > "$FIXTURE/android/gradlew"
chmod +x "$FIXTURE/android/gradlew"

ANDROID_TYPE="$("$ROOT/build.sh" detect --json "$FIXTURE/android" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["type"])')"
[ "$ANDROID_TYPE" = android ] || { echo "Version Catalog Android 감지 실패: $ANDROID_TYPE" >&2; exit 1; }
UBS_TEST_LOG="$FIXTURE/gradle.log" "$ROOT/build.sh" build --project "$FIXTURE/android"
grep -Fqx 'bundleRelease' "$FIXTURE/gradle.log" || {
  echo "Python Gradle adapter가 bundleRelease를 선택하지 않았습니다." >&2
  exit 1
}

# Node adapter는 dependency 입력이 같으면 두 번째 install을 생략한다.
printf '%s\n' '{"scripts":{"build":"node build.js"}}' > "$FIXTURE/node/package.json"
printf '%s\n' '{"lockfileVersion":3,"packages":{}}' > "$FIXTURE/node/package-lock.json"
printf '%s\n' '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$UBS_TEST_LOG"' \
  > "$FIXTURE/bin/npm"
chmod +x "$FIXTURE/bin/npm"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/node.log" \
  "$ROOT/build.sh" build --project "$FIXTURE/node"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/node.log" \
  "$ROOT/build.sh" build --project "$FIXTURE/node"
[ "$(grep -Fxc 'ci --no-fund --no-audit' "$FIXTURE/node.log")" -eq 1 ] || {
  echo "Node dependency install cache가 중복 install을 제거하지 못했습니다." >&2
  exit 1
}
[ "$(grep -Fxc 'run build' "$FIXTURE/node.log")" -eq 2 ] || {
  echo "Node build 실행 횟수가 예상과 다릅니다." >&2
  exit 1
}

# --all 계획과 실제 dry-run은 루트와 하위 프로젝트를 같은 집합으로 선택한다.
printf '%s\n' '{"scripts":{"build":"node root.js"}}' > "$FIXTURE/mono/package.json"
printf '%s\n' '{"scripts":{"build":"node child.js"}}' > "$FIXTURE/mono/apps/child/package.json"
PLAN_JSON="$("$ROOT/build.sh" plan --json --all "$FIXTURE/mono")"
printf '%s' "$PLAN_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 2
assert all(item["adapter"] == "scripts/ubs.py#node" for item in items)
'
PARALLEL_DRY_RUN="$("$ROOT/build.sh" build --all --dry-run --jobs 2 "$FIXTURE/mono")"
printf '%s\n' "$PARALLEL_DRY_RUN" | grep -Fq '전체: 2' || {
  echo "병렬 dry-run 프로젝트 집합이 계획과 다릅니다." >&2
  exit 1
}

if "$ROOT/build.sh" --dry-run --jobs 0 "$FIXTURE/mono" >/dev/null 2>&1; then
  echo "0개의 병렬 job을 허용했습니다." >&2
  exit 1
fi

echo "Python adapter·선택·캐시 테스트 통과"
