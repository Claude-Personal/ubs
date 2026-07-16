#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/lib/detect.sh
source "$REPO_DIR/scripts/lib/detect.sh"

FIXTURE="$(mktemp -d)"
FIXTURE="$(canonical_dir "$FIXTURE")"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p \
  "$FIXTURE/apps/desktop/src-tauri" \
  "$FIXTURE/apps/mobile/android/app" \
  "$FIXTURE/apps/android-app/app" \
  "$FIXTURE/apps/kmp" \
  "$FIXTURE/apps/web" \
  "$FIXTURE/apps/ignored-node"

printf '%s\n' '{"productName":"Desktop","version":"1.0.0"}' \
  > "$FIXTURE/apps/desktop/src-tauri/tauri.conf.json"
printf '%s\n' '[profile.release]' 'lto = "thin"' 'strip = "symbols"' \
  > "$FIXTURE/apps/desktop/src-tauri/Cargo.toml"
printf '%s\n' '{"scripts":{"build":"vite build"},"dependencies":{"react":"latest"}}' \
  > "$FIXTURE/apps/desktop/package.json"

printf '%s\n' 'version: 1.0.0+1' 'dependencies:' '  flutter:' '    sdk: flutter' \
  > "$FIXTURE/apps/mobile/pubspec.yaml"
printf '%s\n' 'pluginManagement {}' > "$FIXTURE/apps/mobile/android/settings.gradle.kts"
printf '%s\n' 'plugins { id("com.android.application") }' \
  > "$FIXTURE/apps/mobile/android/app/build.gradle.kts"

printf '%s\n' 'pluginManagement {}' > "$FIXTURE/apps/android-app/settings.gradle.kts"
printf '%s\n' 'plugins { id("com.android.application") }' \
  'android { buildTypes { release { isMinifyEnabled = true; isShrinkResources = true; proguardFiles("proguard-rules.pro") } } }' \
  > "$FIXTURE/apps/android-app/app/build.gradle.kts"

printf '%s\n' 'pluginManagement {}' > "$FIXTURE/apps/kmp/settings.gradle.kts"
printf '%s\n' 'plugins { kotlin("multiplatform") }' > "$FIXTURE/apps/kmp/build.gradle.kts"

printf '%s\n' '{"scripts":{"build":"vite build"},"dependencies":{"react":"latest"}}' \
  > "$FIXTURE/apps/web/package.json"
printf '%s\n' '{"scripts":{"test":"node test.js"}}' \
  > "$FIXTURE/apps/ignored-node/package.json"

RESULT="$(scan_projects "$FIXTURE")"

assert_line() {
  local expected="$1"
  if ! printf '%s\n' "$RESULT" | grep -Fqx "$expected"; then
    echo "누락된 감지 결과: $expected" >&2
    printf '%s\n' "$RESULT" >&2
    exit 1
  fi
}

assert_line "tauri"$'\t'"$FIXTURE/apps/desktop"
assert_line "flutter"$'\t'"$FIXTURE/apps/mobile"
assert_line "android"$'\t'"$FIXTURE/apps/android-app"
assert_line "kotlin-multiplatform"$'\t'"$FIXTURE/apps/kmp"
assert_line "react"$'\t'"$FIXTURE/apps/web"

COUNT=$(printf '%s\n' "$RESULT" | sed '/^$/d' | wc -l | tr -d ' ')
[ "$COUNT" -eq 5 ] || {
  echo "프로젝트 수가 예상과 다릅니다: expected=5 actual=$COUNT" >&2
  printf '%s\n' "$RESULT" >&2
  exit 1
}

DETECT_JSON="$(bash "$REPO_DIR/build.sh" detect --json "$FIXTURE")"
printf '%s' "$DETECT_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 5
assert {item["type"] for item in items} == {"tauri", "flutter", "android", "kotlin-multiplatform", "react"}
'

AUDIT_JSON="$(bash "$REPO_DIR/build.sh" audit --json "$FIXTURE")"
printf '%s' "$AUDIT_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert items
by_check = {(item["type"], item["check"]): item["status"] for item in items}
assert by_check[("flutter", "native-symbols")] == "enforced"
assert by_check[("flutter", "web")] == "not-supported"
assert by_check[("tauri", "rust-lto")] == "configured"
assert by_check[("tauri", "rust-strip")] == "configured"
assert by_check[("android", "android-minify")] == "configured"
assert by_check[("android", "resource-shrinking")] == "configured"
assert by_check[("android", "r8-rules")] == "configured"
assert by_check[("react", "javascript")] == "not-configured"
'

PLAN_JSON="$(bash "$REPO_DIR/build.sh" plan --json --type flutter \
  --flutter-outputs appbundle,web "$FIXTURE")"
printf '%s' "$PLAN_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 1
item = items[0]
assert item["type"] == "flutter"
assert item["adapter"] == "scripts/build-flutter.sh"
assert item["options"]["outputs"] == "appbundle,web"
assert item["options"]["output_selection"] == "explicit"
assert item["options"]["platform"] is None
assert item["options"]["skip_clean"] is True
assert item["options"]["version_bump"] == "none"
'

PLAN_ALL_JSON="$(UBS_SKIP_INSTALL=true TAURI_OBFUSCATE_JS=true \
  UBS_GRADLE_TASK=assembleRelease UBS_NODE_BUILD_SCRIPT=build:production \
  bash "$REPO_DIR/build.sh" plan --json "$FIXTURE")"
printf '%s' "$PLAN_ALL_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 5
by_type = {item["type"]: item for item in items}
assert by_type["tauri"]["options"]["skip_install"] is True
assert by_type["tauri"]["options"]["obfuscate_js"] is True
assert by_type["android"]["options"]["gradle_task"] == "assembleRelease"
assert by_type["react"]["options"]["build_script"] == "build:production"
assert by_type["react"]["options"]["skip_install"] is True
'

PLAN_PROJECT_JSON="$(bash "$REPO_DIR/build.sh" plan --json \
  --project "$FIXTURE/apps/web" "$FIXTURE")"
printf '%s' "$PLAN_PROJECT_JSON" | python3 -c '
import json, sys
items = json.load(sys.stdin)
assert len(items) == 1
assert items[0]["type"] == "react"
assert items[0]["path"].endswith("/apps/web")
'

DRY_RUN="$(bash "$REPO_DIR/build.sh" build --all --dry-run "$FIXTURE")"
DRY_COUNT=$(printf '%s\n' "$DRY_RUN" | grep -c '(dry-run)')
[ "$DRY_COUNT" -eq 5 ] || {
  echo "dry-run 프로젝트 수가 예상과 다릅니다: expected=5 actual=$DRY_COUNT" >&2
  printf '%s\n' "$DRY_RUN" >&2
  exit 1
}

AUTO_DRY_RUN="$(bash "$REPO_DIR/build.sh" --dry-run "$FIXTURE")"
AUTO_COUNT=$(printf '%s\n' "$AUTO_DRY_RUN" | grep -c '(dry-run)')
[ "$AUTO_COUNT" -eq 5 ] || {
  echo "기본 명령이 모노레포 전체를 자동 선택하지 않았습니다." >&2
  printf '%s\n' "$AUTO_DRY_RUN" >&2
  exit 1
}

FLUTTER_PLAN="$(bash "$REPO_DIR/build.sh" --dry-run --type flutter \
  --flutter-outputs appbundle,web "$FIXTURE")"
printf '%s\n' "$FLUTTER_PLAN" | grep -Fq 'Flutter outputs=appbundle,web' || {
  echo "dry-run에 Flutter 출력 계획이 표시되지 않았습니다." >&2
  exit 1
}
if bash "$REPO_DIR/build.sh" --dry-run --flutter-outputs appbundle, "$FIXTURE" \
  >/dev/null 2>&1; then
  echo "잘못된 Flutter 출력 목록을 허용했습니다." >&2
  exit 1
fi

# 어댑터가 생태계별 안전한 기본 명령을 선택하는지 외부 빌드 없이 검증한다.
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" > "$UBS_TEST_LOG"' \
  > "$FIXTURE/apps/android-app/gradlew"
chmod +x "$FIXTURE/apps/android-app/gradlew"
UBS_PROJECT_TYPE=android UBS_TEST_LOG="$FIXTURE/gradle.log" \
  bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/android-app" "$REPO_DIR/scripts/build-gradle.sh"
grep -Fqx 'bundleRelease' "$FIXTURE/gradle.log" || {
  echo "Android 기본 Gradle task가 bundleRelease가 아닙니다." >&2
  exit 1
}

mkdir -p "$FIXTURE/bin"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >> "$UBS_TEST_LOG"' \
  > "$FIXTURE/bin/npm"
chmod +x "$FIXTURE/bin/npm"
printf '%s\n' '{}' > "$FIXTURE/apps/web/package-lock.json"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/node.log" \
  bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/web" "$REPO_DIR/scripts/build-node.sh"
grep -Fqx 'ci --no-fund --no-audit' "$FIXTURE/node.log" || {
  echo "npm lock 파일에서 npm ci를 선택하지 않았습니다." >&2
  exit 1
}
grep -Fqx 'run build' "$FIXTURE/node.log" || {
  echo "Node build script를 실행하지 않았습니다." >&2
  exit 1
}

printf '%s\n' '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$UBS_TEST_LOG"' \
  'if [ "${UBS_TEST_FAIL:-false}" = true ] && [ "$1 $2" = "build appbundle" ]; then exit 7; fi' \
  > "$FIXTURE/bin/flutter"
chmod +x "$FIXTURE/bin/flutter"
printf '%s\n' '# build-time public configuration only' > "$FIXTURE/apps/mobile/.env"

PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/flutter.log" \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=patch UBS_FLUTTER_PLATFORM=android \
  UBS_SKIP_CLEAN=true UBS_NO_NOTIFY=true bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/mobile" "$REPO_DIR/scripts/build-flutter.sh"
grep -Fqx 'version: 1.0.1+2' "$FIXTURE/apps/mobile/pubspec.yaml" || {
  echo "성공한 Flutter 빌드의 버전 변경이 유지되지 않았습니다." >&2
  exit 1
}

: > "$FIXTURE/flutter-outputs.log"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/flutter-outputs.log" \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=none UBS_FLUTTER_OUTPUTS=appbundle,apk,web \
  UBS_SKIP_CLEAN=true UBS_NO_NOTIFY=true bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/mobile" "$REPO_DIR/scripts/build-flutter.sh"
grep -Fq 'build appbundle --release' "$FIXTURE/flutter-outputs.log" || {
  echo "Flutter 다중 출력에서 AAB가 실행되지 않았습니다." >&2
  exit 1
}
grep -Fq 'build apk --release' "$FIXTURE/flutter-outputs.log" || {
  echo "Flutter 다중 출력에서 APK가 실행되지 않았습니다." >&2
  exit 1
}
grep -Fq -- '--split-per-abi' "$FIXTURE/flutter-outputs.log" || {
  echo "Flutter APK에 ABI 분할이 적용되지 않았습니다." >&2
  exit 1
}
grep -Fq 'build web --release' "$FIXTURE/flutter-outputs.log" || {
  echo "Flutter 다중 출력에서 Web이 실행되지 않았습니다." >&2
  exit 1
}

printf '%s\n' 'version: 1.0.0+1' 'dependencies:' '  flutter:' '    sdk: flutter' \
  > "$FIXTURE/apps/mobile/pubspec.yaml"
rm -f "$FIXTURE/apps/mobile/.env"
if PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/flutter-fail.log" UBS_TEST_FAIL=true \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=patch UBS_FLUTTER_PLATFORM=android \
  UBS_SKIP_CLEAN=true UBS_NO_NOTIFY=true bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/mobile" "$REPO_DIR/scripts/build-flutter.sh" >/dev/null 2>&1; then
  echo "실패하도록 구성한 Flutter 빌드가 성공했습니다." >&2
  exit 1
fi
grep -Fqx 'version: 1.0.0+1' "$FIXTURE/apps/mobile/pubspec.yaml" || {
  echo "실패한 Flutter 빌드에서 원래 버전이 복원되지 않았습니다." >&2
  exit 1
}

# Tauri 어댑터는 macOS 전용이므로 CI 운영체제와 무관하게 macOS 분기를 검증한다.
printf '%s\n' '#!/usr/bin/env bash' 'echo Darwin' > "$FIXTURE/bin/uname"
chmod +x "$FIXTURE/bin/uname"

printf '%s\n' \
  'TAURI_SIGN_IDENTITY="$(touch should-not-exist)"' \
  'TAURI_INSTALLER_IDENTITY="Installer"' \
  > "$FIXTURE/apps/desktop/.env.macos"
if PATH="$FIXTURE/bin:$PATH" \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=none UBS_TAURI_PACKAGE_MODE=signed \
  bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/desktop" "$REPO_DIR/scripts/build-tauri-macos.sh" >/dev/null 2>&1; then
  echo "서명 파일이 없는 Tauri 테스트가 성공했습니다." >&2
  exit 1
fi
[ ! -e "$FIXTURE/apps/desktop/should-not-exist" ] || {
  echo ".env.macos 내용이 셸 명령으로 실행됐습니다." >&2
  exit 1
}

printf '%s\n' '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$UBS_TEST_LOG"' \
  'if [ "$1 $2" = "run tauri" ]; then mkdir -p "src-tauri/target/release/bundle/macos/Desktop.app/Contents"; fi' \
  > "$FIXTURE/bin/npm"
chmod +x "$FIXTURE/bin/npm"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/tauri.log" \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=none UBS_TAURI_PACKAGE_MODE=auto \
  UBS_SKIP_INSTALL=true UBS_NO_NOTIFY=true \
  bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/desktop" "$REPO_DIR/scripts/build-tauri-macos.sh"
[ -d "$FIXTURE/apps/desktop/src-tauri/target/release/bundle/macos/Desktop.app" ] || {
  echo "서명 설정이 없는 Tauri 자동 모드에서 .app이 유지되지 않았습니다." >&2
  exit 1
}
[ ! -e "$FIXTURE/apps/desktop/should-not-exist" ] || {
  echo "Tauri 자동 모드에서 .env.macos 내용이 실행됐습니다." >&2
  exit 1
}

mkdir -p "$FIXTURE/apps/desktop/signing"
printf '%s\n' 'profile' > "$FIXTURE/apps/desktop/signing/App.provisionprofile"
printf '%s\n' '<plist />' > "$FIXTURE/apps/desktop/signing/app.entitlements"
printf '%s\n' \
  'TAURI_SIGN_IDENTITY="Apple Distribution: Test"' \
  'TAURI_INSTALLER_IDENTITY="Installer: Test"' \
  'TAURI_PROVISION_PROFILE=signing/App.provisionprofile' \
  'TAURI_ENTITLEMENTS=signing/app.entitlements' \
  > "$FIXTURE/apps/desktop/.env.macos"
printf '%s\n' '#!/usr/bin/env bash' 'printf "xattr %s\n" "$*" >> "$UBS_TEST_LOG"' \
  > "$FIXTURE/bin/xattr"
printf '%s\n' '#!/usr/bin/env bash' 'printf "codesign %s\n" "$*" >> "$UBS_TEST_LOG"' \
  > "$FIXTURE/bin/codesign"
printf '%s\n' '#!/usr/bin/env bash' \
  'printf "productbuild %s\n" "$*" >> "$UBS_TEST_LOG"' \
  'for value in "$@"; do output="$value"; done' \
  'mkdir -p "$(dirname "$output")"' ': > "$output"' \
  > "$FIXTURE/bin/productbuild"
chmod +x "$FIXTURE/bin/xattr" "$FIXTURE/bin/codesign" "$FIXTURE/bin/productbuild"
PATH="$FIXTURE/bin:$PATH" UBS_TEST_LOG="$FIXTURE/tauri-signed.log" \
  UBS_NON_INTERACTIVE=true UBS_VERSION_BUMP=none UBS_TAURI_PACKAGE_MODE=signed \
  UBS_SKIP_INSTALL=true UBS_NO_NOTIFY=true \
  bash -c 'cd "$1" && bash "$2"' _ \
  "$FIXTURE/apps/desktop" "$REPO_DIR/scripts/build-tauri-macos.sh"
[ -f "$FIXTURE/apps/desktop/signing/build/Desktop.pkg" ] || {
  echo "Tauri signed 모드에서 .pkg가 생성되지 않았습니다." >&2
  exit 1
}
grep -Fq 'xattr -cr signing/App.provisionprofile' "$FIXTURE/tauri-signed.log" || {
  echo "Tauri signed 모드에서 quarantine 속성 제거가 실행되지 않았습니다." >&2
  exit 1
}

echo "감지 테스트 통과 (5 projects)"
