#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/bin" "$FIXTURE/android/app" "$FIXTURE/android/gradle" \
  "$FIXTURE/mono/apps/child" "$FIXTURE/node" "$FIXTURE/workspace/apps/a" \
  "$FIXTURE/tauri-mixed/src-tauri" "$FIXTURE/tauri-nested/src-tauri" \
  "$FIXTURE/tauri-nested/frontend"

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
printf '%s\n' 'legacy-peer-deps=true' > "$FIXTURE/node/.npmrc"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/node.log" \
  "$ROOT/build.sh" build --project "$FIXTURE/node"
[ "$(grep -Fxc 'ci --no-fund --no-audit' "$FIXTURE/node.log")" -eq 2 ] || {
  echo "Node dependency install cache가 중복 install을 제거하지 못했습니다." >&2
  exit 1
}
[ "$(grep -Fxc 'run build' "$FIXTURE/node.log")" -eq 3 ] || {
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
assert all(item["options"]["jobs"] == 1 for item in items)
assert all(item["options"]["install_mode"] == "auto" for item in items)
assert all(item["options"]["package_manager"] == "npm" for item in items)
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

# workspace child는 루트 package manager/lockfile을 사용하고 같은 실행 그룹으로 직렬화한다.
printf '%s\n' '{"packageManager":"pnpm@9.15.0","workspaces":["apps/*"],"scripts":{"build":"pnpm -r build"}}' \
  > "$FIXTURE/workspace/package.json"
printf '%s\n' 'lockfileVersion: 9' > "$FIXTURE/workspace/pnpm-lock.yaml"
printf '%s\n' '{"scripts":{"build":"node build.js"}}' > "$FIXTURE/workspace/apps/a/package.json"
printf '%s\n' '#!/usr/bin/env bash' \
  'if [ "${1:-}" = "--version" ]; then echo 9.15.0; exit 0; fi' \
  'printf "%s|%s\n" "$PWD" "$*" >> "$UBS_TEST_LOG"' > "$FIXTURE/bin/pnpm"
chmod +x "$FIXTURE/bin/pnpm"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/pnpm.log" \
  "$ROOT/build.sh" build --project "$FIXTURE/workspace/apps/a"
grep -Fq "$FIXTURE/workspace|install --frozen-lockfile" "$FIXTURE/pnpm.log" || {
  echo "workspace root에서 pnpm install을 실행하지 않았습니다." >&2
  exit 1
}
grep -Fq "$FIXTURE/workspace/apps/a|run build" "$FIXTURE/pnpm.log" || {
  echo "workspace child build 위치가 잘못됐습니다." >&2
  exit 1
}
WORKSPACE_PLAN="$(PATH="$FIXTURE/bin:$PATH" "$ROOT/build.sh" plan --json --all --jobs 2 "$FIXTURE/workspace")"
printf '%s' "$WORKSPACE_PLAN" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 2
assert {item["options"]["package_manager"] for item in items} == {"pnpm"}
assert len({item["options"]["execution_group"] for item in items}) == 1
'

# legacy Node wrapper는 복합 Tauri 프로젝트도 Node adapter로 강제한다.
printf '%s\n' '{"scripts":{"build":"vite build"}}' > "$FIXTURE/tauri-mixed/package.json"
printf '%s\n' '{"productName":"Mixed","version":"1.0.0"}' > "$FIXTURE/tauri-mixed/src-tauri/tauri.conf.json"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/mixed.log" UBS_SKIP_INSTALL=true \
  bash -c 'cd "$1" && bash "$2"' _ "$FIXTURE/tauri-mixed" "$ROOT/scripts/build-node.sh"
grep -Fqx 'run build' "$FIXTURE/mixed.log" || {
  echo "legacy Node wrapper가 Node adapter를 실행하지 않았습니다." >&2
  exit 1
}

# Tauri가 명시한 nested frontend는 별도 React 프로젝트로 중복 감지하지 않는다.
printf '%s\n' '{"productName":"Nested","version":"1.0.0","build":{"frontendDist":"../frontend/dist","beforeBuildCommand":"cd frontend && npm run build"}}' \
  > "$FIXTURE/tauri-nested/src-tauri/tauri.conf.json"
printf '%s\n' '{"scripts":{"build":"vite build"},"dependencies":{"react":"latest"}}' \
  > "$FIXTURE/tauri-nested/frontend/package.json"
NESTED_JSON="$("$ROOT/build.sh" detect --json "$FIXTURE/tauri-nested")"
printf '%s' "$NESTED_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 1 and items[0]["type"] == "tauri", items
'

# Gradle plan은 실제 최적화 flags를 구조화하고 Windows 경로를 보존한다.
GRADLE_PLAN="$(UBS_GRADLE_OPTIMIZE=true UBS_GRADLE_FLAGS='--scan' \
  "$ROOT/build.sh" plan --json "$FIXTURE/android")"
printf '%s' "$GRADLE_PLAN" | python3 -c '
import json, sys
options = json.load(sys.stdin)[0]["options"]
assert options["gradle_optimize"] is True
assert options["gradle_arguments"] == ["bundleRelease", "--build-cache", "--parallel", "--scan"]
'
python3 - "$ROOT/scripts/ubs.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ubs", sys.argv[1])
ubs = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = ubs
spec.loader.exec_module(ubs)
value = r'-PstoreFile=C:\Users\me\release.jks "-Pcache=C:\build cache"'
assert ubs.split_cli_arguments(value, windows=True) == [
    r'-PstoreFile=C:\Users\me\release.jks', r'-Pcache=C:\build cache'
]
PY

echo "Python adapter·선택·캐시 테스트 통과"
