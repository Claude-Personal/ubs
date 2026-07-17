#!/bin/bash

# =================================================================
# Tauri cross-platform production build script (plus macOS signing/package)
# Description: Tauri 2 production bundles on Windows/macOS/Linux, with
#              optional macOS App Store codesign and installer packaging.
# Features: Auto Version Bump, cross-platform bundle discovery, macOS .pkg
# Warning: 90886 재발 시 entitlements에 application-identifier를 수동 주입하지 말고 Apple Developer Forums / Tauri 이슈를 확인하세요.
# =================================================================

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==========================================
# 빌드 스크립트 자체 업데이트 확인
# ==========================================

check_script_update() {
  [ "${UBS_ALLOW_SELF_UPDATE:-false}" = "true" ] || return 0
  echo -e "${YELLOW}UBS_ALLOW_SELF_UPDATE는 폐기됐습니다. 검증된 중앙 명령을 사용하세요: ./build.sh update${NC}" >&2
}

check_script_update "$@"

# ==========================================
# 프로젝트 확인
# ==========================================

CONF="src-tauri/tauri.conf.json"
if [ ! -f "$CONF" ]; then
  echo -e "${RED}❌ src-tauri/tauri.conf.json 을 찾을 수 없습니다.${NC}"
  echo -e "${YELLOW}   Tauri 프로젝트 루트에서 실행하세요.${NC}"
  exit 1
fi

HOST_OS="$(uname -s)"

command -v python3 >/dev/null 2>&1 || { echo -e "${RED}❌ python3 이 필요합니다.${NC}"; exit 1; }

APP_NAME=$(python3 -c "import json;print(json.load(open('$CONF'))['productName'])")
CURRENT_VERSION=$(python3 -c "import json;print(json.load(open('$CONF'))['version'])")

echo -e "${CYAN}📦 앱: $APP_NAME  |  현재 버전: $CURRENT_VERSION${NC}"

# ==========================================
# 버전 자동 업데이트 (앱 버전)
# ==========================================

VERSION_NAME="$CURRENT_VERSION"

VERSION_CHANGED=false
BUILD_COMPLETED=false

set_tauri_version() {
  local version="$1"
  python3 - "$CONF" "$version" <<'PYEOF'
import re, sys
path, new_version = sys.argv[1], sys.argv[2]
content = open(path).read()
content = re.sub(r'("version":\s*")[^"]+(")', rf'\g<1>{new_version}\g<2>', content, count=1)
open(path, "w").write(content)
PYEOF
}

restore_version_if_incomplete() {
  if [ "$VERSION_CHANGED" = true ] && [ "$BUILD_COMPLETED" != true ]; then
    set_tauri_version "$CURRENT_VERSION"
    echo -e "${YELLOW}↩️  빌드가 완료되지 않아 버전을 $CURRENT_VERSION 으로 복원했습니다.${NC}" >&2
  fi
}
trap restore_version_if_incomplete EXIT

if [ "${UBS_NON_INTERACTIVE:-false}" = "true" ]; then
  case "${UBS_VERSION_BUMP:-none}" in
    patch) VERSION_CHOICE=1 ;;
    minor) VERSION_CHOICE=2 ;;
    major) VERSION_CHOICE=3 ;;
    none) VERSION_CHOICE=4 ;;
    *) echo -e "${RED}지원하지 않는 UBS_VERSION_BUMP 값입니다.${NC}" >&2; exit 2 ;;
  esac
  echo -e "${CYAN}비대화형 버전 정책: ${UBS_VERSION_BUMP:-none}${NC}"
else
  echo -e "${CYAN}어떤 버전을 올릴까요?${NC}"
  echo -e "  ${YELLOW}1) Patch 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')"
  echo -e "  ${YELLOW}2) Minor 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')"
  echo -e "  ${YELLOW}3) Major 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')"
  echo -e "  ${YELLOW}4) 버전 유지${NC}"
  echo -e "  ${YELLOW}5) 취소${NC}"
  read -p "선택 (1-5): " VERSION_CHOICE
fi

case $VERSION_CHOICE in
  1) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}') ;;
  2) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}') ;;
  3) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}') ;;
  4) NEW_VERSION="$CURRENT_VERSION"; echo -e "${CYAN}버전 유지: $NEW_VERSION${NC}" ;;
  5) echo -e "${YELLOW}빌드를 취소했습니다.${NC}"; exit 0 ;;
  *) echo -e "${RED}잘못된 선택입니다. 버전을 유지합니다.${NC}"; NEW_VERSION="$CURRENT_VERSION" ;;
esac

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  set_tauri_version "$NEW_VERSION"
  VERSION_CHANGED=true
  echo -e "${GREEN}✅ 버전 업데이트: $CURRENT_VERSION → $NEW_VERSION${NC}"
fi

# ==========================================
# 서명 설정 확인 (.env.macos)
# ==========================================

ENV_FILE=".env.macos"
dotenv_value() {
  python3 - "$ENV_FILE" "$1" <<'PYEOF'
import sys
path, wanted = sys.argv[1], sys.argv[2]
try:
    for raw in open(path, encoding="utf-8"):
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.strip() != wanted:
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        print(value, end="")
        break
except FileNotFoundError:
    pass
PYEOF
}

if [ -f "$ENV_FILE" ]; then
  TAURI_SIGN_IDENTITY="${TAURI_SIGN_IDENTITY:-$(dotenv_value TAURI_SIGN_IDENTITY)}"
  TAURI_INSTALLER_IDENTITY="${TAURI_INSTALLER_IDENTITY:-$(dotenv_value TAURI_INSTALLER_IDENTITY)}"
  TAURI_PROVISION_PROFILE="${TAURI_PROVISION_PROFILE:-$(dotenv_value TAURI_PROVISION_PROFILE)}"
  TAURI_ENTITLEMENTS="${TAURI_ENTITLEMENTS:-$(dotenv_value TAURI_ENTITLEMENTS)}"
  TAURI_OBFUSCATE_JS="${TAURI_OBFUSCATE_JS:-$(dotenv_value TAURI_OBFUSCATE_JS)}"
fi

SIGNING_DIR="signing"
PROVISION_PROFILE="${TAURI_PROVISION_PROFILE:-$(find "$SIGNING_DIR" -maxdepth 1 -iname '*.provisionprofile' 2>/dev/null | head -1)}"
ENTITLEMENTS="${TAURI_ENTITLEMENTS:-$(find "$SIGNING_DIR" -maxdepth 1 -iname '*.entitlements' 2>/dev/null | head -1)}"
PACKAGE_MODE="${UBS_TAURI_PACKAGE_MODE:-auto}"
SIGN_PACKAGE=false
SIGNING_READY=true
[ -n "${TAURI_SIGN_IDENTITY:-}" ] || SIGNING_READY=false
[ -n "${TAURI_INSTALLER_IDENTITY:-}" ] || SIGNING_READY=false
[ -n "$PROVISION_PROFILE" ] && [ -f "$PROVISION_PROFILE" ] || SIGNING_READY=false
[ -n "$ENTITLEMENTS" ] && [ -f "$ENTITLEMENTS" ] || SIGNING_READY=false

case "$PACKAGE_MODE" in
  auto)
    if [ "$HOST_OS" != "Darwin" ]; then
      echo -e "${CYAN}ℹ️  ${HOST_OS}에서는 Tauri 기본 번들을 생성합니다. Apple .pkg 서명은 macOS 전용입니다.${NC}"
    elif [ "$SIGNING_READY" = true ]; then SIGN_PACKAGE=true
    else echo -e "${YELLOW}ℹ️  Apple 서명 설정이 불완전하여 기본 Tauri .app 빌드만 생성합니다.${NC}"
    fi
    ;;
  signed)
    if [ "$HOST_OS" != "Darwin" ]; then
      echo -e "${RED}❌ signed 모드의 Apple .pkg 생성은 macOS에서만 지원합니다.${NC}" >&2
      exit 1
    fi
    if [ "$SIGNING_READY" != true ]; then
      echo -e "${RED}❌ signed 모드에는 서명 identity, provisioning profile, entitlements가 모두 필요합니다.${NC}" >&2
      exit 1
    fi
    SIGN_PACKAGE=true
    ;;
  unsigned) SIGN_PACKAGE=false ;;
  *) echo -e "${RED}❌ UBS_TAURI_PACKAGE_MODE는 auto, signed, unsigned 중 하나여야 합니다.${NC}" >&2; exit 2 ;;
esac

if [ "$SIGN_PACKAGE" = true ]; then
  echo -e "${CYAN}🔑 서명 ID: $TAURI_SIGN_IDENTITY${NC}"
  echo -e "${CYAN}📄 Provisioning Profile: $PROVISION_PROFILE${NC}"
fi

# ==========================================
# 환경변수 주입 확인 (.env → import.meta.env)
# ==========================================

# Vite는 프로젝트 루트의 .env / .env.production 을 별도 플래그 없이 자동으로 읽어
# `VITE_` 접두사가 붙은 값을 import.meta.env.VITE_* 로 프런트엔드 빌드에 주입한다.
# (Flutter의 --dart-define-from-file 과 동일한 역할, Vite는 기본 내장 기능)
if [ -f ".env" ] || [ -f ".env.production" ]; then
  echo -e "${CYAN}🔑 프런트엔드 .env 감지됨 — Vite가 빌드 시 자동 주입합니다.${NC}"
fi

# ==========================================
# JS 난독화 옵션 (TAURI_OBFUSCATE_JS=true)
# ==========================================

# Tauri 프런트엔드(JS/TS)는 Dart AOT처럼 네이티브로 컴파일되지 않고 텍스트로 번들에 포함된다.
# Vite가 기본으로 minify는 하지만(변수명 축약) 진짜 난독화(제어 흐름 변형, 문자열 암호화)는 아니다.
# 이 옵션을 켜면 javascript-obfuscator로 dist/ 산출물을 한 번 더 난독화한 뒤,
# --config로 beforeBuildCommand를 비워 tauri build가 그 결과를 덮어쓰지 않게 한다.
OBFUSCATE_JS="${TAURI_OBFUSCATE_JS:-false}"

# ==========================================
# macOS 유니버설 바이너리 (Apple Silicon + Intel)
# ==========================================

# tauri build --target universal-apple-darwin는 aarch64/x86_64 두 슬라이스를
# lipo로 합친 .app 하나를 만든다 — 배포 산출물은 여전히 1개.
TAURI_TARGET_ARGS=()
if [ "$HOST_OS" = "Darwin" ] && [ "${TAURI_UNIVERSAL_MACOS:-true}" = "true" ]; then
  if command -v rustup >/dev/null 2>&1; then
    for triple in aarch64-apple-darwin x86_64-apple-darwin; do
      rustup target list --installed 2>/dev/null | grep -qx "$triple" || rustup target add "$triple"
    done
    echo -e "${CYAN}🌐 macOS 유니버설 바이너리(Apple Silicon + Intel)로 빌드합니다. 끄려면: TAURI_UNIVERSAL_MACOS=false${NC}"
    TAURI_TARGET_ARGS=(--target universal-apple-darwin)
  else
    echo -e "${YELLOW}⚠️  rustup이 없어 유니버설 빌드를 건너뜁니다. 현재 아키텍처로만 빌드합니다.${NC}"
  fi
fi

# ==========================================
# 빌드 시작
# ==========================================

BUILD_START_TS=$(date +%s)

# shellcheck source=lib/node-package-manager.sh
source "$SCRIPT_DIR/lib/node-package-manager.sh"
detect_node_package_manager
if [ "${UBS_SKIP_INSTALL:-false}" != "true" ]; then
  echo -e "${BLUE}📥 $NODE_PM install...${NC}"
  install_node_dependencies
else
  echo -e "${CYAN}ℹ️  UBS_SKIP_INSTALL=true — 의존성 설치를 건너뜁니다.${NC}"
fi

if [ "$OBFUSCATE_JS" = "true" ]; then
  echo -e "${BLUE}🚀 [1/4] 프런트엔드 빌드...${NC}"
  run_node_script build

  echo -e "${YELLOW}🔒 [2/4] JS 난독화 (lockfile에 고정된 javascript-obfuscator)...${NC}"
  OBFUSCATOR="$NODE_WORKSPACE_ROOT/node_modules/.bin/javascript-obfuscator"
  OBFUSCATOR_CMD=("$OBFUSCATOR")
  if [ "${OS:-}" = "Windows_NT" ] && [ -f "$OBFUSCATOR.cmd" ]; then
    OBFUSCATOR_CMD=(cmd.exe /c "$OBFUSCATOR.cmd")
  fi
  [ -x "$OBFUSCATOR" ] || [ ${#OBFUSCATOR_CMD[@]} -gt 1 ] || {
    echo -e "${RED}❌ javascript-obfuscator를 로컬 dependency에서 찾을 수 없습니다.${NC}" >&2
    echo -e "${YELLOW}   devDependency와 lockfile에 고정한 뒤 다시 설치하세요.${NC}" >&2
    exit 1
  }
  if ! "${OBFUSCATOR_CMD[@]}" dist --output dist \
    --compact true --control-flow-flattening true --string-array true \
    --string-array-encoding base64 --self-defending true; then
    echo -e "${RED}❌ javascript-obfuscator 실행 실패 — 난독화 안 된 결과가 패키징되지 않도록 중단합니다.${NC}"
    exit 1
  fi

  echo -e "${BLUE}🚀 [3/4] tauri build (프런트엔드 재빌드 스킵)...${NC}"
  run_node_script tauri build -- --config '{"build":{"beforeBuildCommand":""}}' "${TAURI_TARGET_ARGS[@]}" "$@"
else
  echo -e "${BLUE}🚀 [1/3] tauri build...${NC}"
  run_node_script tauri build -- "${TAURI_TARGET_ARGS[@]}" "$@"
  echo -e "${CYAN}ℹ️  JS 난독화는 기본 꺼져있음 — 켜려면: ./build.sh --obfuscate-js${NC}"
fi

if [ "$HOST_OS" = "Darwin" ]; then
  BUNDLE_TARGET_DIR="release"
  [ ${#TAURI_TARGET_ARGS[@]} -eq 0 ] || BUNDLE_TARGET_DIR="${TAURI_TARGET_ARGS[1]}/release"
  BUNDLE_APP="src-tauri/target/${BUNDLE_TARGET_DIR}/bundle/macos/${APP_NAME}.app"
  [ -d "$BUNDLE_APP" ] || { echo -e "${RED}❌ 빌드 결과 .app 을 찾을 수 없습니다: $BUNDLE_APP${NC}"; exit 1; }
  ARTIFACT_OUT="$BUNDLE_APP"
else
  ARTIFACT_OUT="$(find src-tauri/target/release/bundle -mindepth 2 -maxdepth 3 \( -type f -o -type d \) 2>/dev/null | head -1)"
  [ -n "$ARTIFACT_OUT" ] || { echo -e "${RED}❌ Tauri 번들 산출물을 찾을 수 없습니다: src-tauri/target/release/bundle${NC}"; exit 1; }
fi
RESULT_DIR="$(dirname "$ARTIFACT_OUT")"
ARTIFACT_LABEL="$(basename "$ARTIFACT_OUT")"

if [ "$SIGN_PACKAGE" = true ]; then
  echo -e "${YELLOW}🛡️ Codesigning (Apple Distribution)...${NC}"
  echo -e "${CYAN}🧹 Provisioning profile 및 앱 번들의 확장 속성을 제거합니다...${NC}"
  xattr -cr "$PROVISION_PROFILE" "$BUNDLE_APP"
  cp "$PROVISION_PROFILE" "$BUNDLE_APP/Contents/embedded.provisionprofile"
  codesign --deep --force --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$TAURI_SIGN_IDENTITY" \
    "$BUNDLE_APP"
  codesign --verify --deep --strict --verbose=2 "$BUNDLE_APP"

  echo -e "${YELLOW}📦 Building signed installer package (.pkg)...${NC}"
  mkdir -p "$SIGNING_DIR/build"
  PKG_OUT="$SIGNING_DIR/build/${APP_NAME}.pkg"
  productbuild --component "$BUNDLE_APP" /Applications \
    --sign "$TAURI_INSTALLER_IDENTITY" \
    "$PKG_OUT"
  ARTIFACT_OUT="$PKG_OUT"
  RESULT_DIR="$SIGNING_DIR/build"
  ARTIFACT_LABEL="$APP_NAME.pkg"
fi
BUILD_COMPLETED=true

# ==========================================
# 빌드 완료 알림
# ==========================================

BUILD_END_TS=$(date +%s)
BUILD_ELAPSED=$((BUILD_END_TS - BUILD_START_TS))
BUILD_ELAPSED_MIN=$((BUILD_ELAPSED / 60))
BUILD_ELAPSED_SEC=$((BUILD_ELAPSED % 60))
BUILD_ELAPSED_FMT="${BUILD_ELAPSED_MIN}m ${BUILD_ELAPSED_SEC}s"

if [[ "$OSTYPE" == "darwin"* ]] && [ "${UBS_NO_NOTIFY:-false}" != "true" ]; then
  # 빌드는 이미 성공했으므로 알림 명령 실패로 스크립트 전체가 죽지 않도록 best-effort 처리.
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
  say "Build process completed successfully" 2>/dev/null || true
  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "✅ Build Finished" subtitle (item 2 of argv)' \
    -e 'end run' \
    "Version $NEW_VERSION 빌드 완료 ($BUILD_ELAPSED_FMT)" \
    "$ARTIFACT_LABEL is ready" 2>/dev/null || true
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version : $NEW_VERSION"
echo -e "📍 Artifact : $ARTIFACT_OUT"
echo -e "⏱️  빌드 시간 : $BUILD_ELAPSED_FMT"
echo -e "------------------------------------------------------------"
if [ "$SIGN_PACKAGE" = true ]; then
  echo -e "${CYAN}ℹ️  Transporter 앱으로 $ARTIFACT_OUT 를 업로드하면 App Store Connect 에 반영됩니다.${NC}"
fi
