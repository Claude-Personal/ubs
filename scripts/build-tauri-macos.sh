#!/bin/bash

# =================================================================
# Tauri macOS Production Build Script
# Description: Automated Build + Codesign + Installer Package for
#              Tauri 2.0 macOS apps (App Store / notarized distribution)
# Features: Auto Version Bump, Codesign, productbuild .pkg, Smart Notifications
# =================================================================

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==========================================
# 빌드 스크립트 자체 업데이트 확인
# ==========================================

SCRIPT_VERSION="1.2.0"
REPO_RAW="https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main"

check_script_update() {
  local remote_version
  remote_version=$(curl -fsSL --max-time 3 "$REPO_RAW/scripts/TAURI_VERSION" 2>/dev/null | tr -d '[:space:]')
  [ -z "$remote_version" ] && return

  local latest
  latest=$(printf '%s\n%s\n' "$SCRIPT_VERSION" "$remote_version" | sort -V | tail -1)
  [ "$latest" != "$remote_version" ] && return
  [ "$remote_version" = "$SCRIPT_VERSION" ] && return

  echo -e "${YELLOW}🔔 새 버전의 빌드 스크립트가 있습니다: ${SCRIPT_VERSION} → ${remote_version}${NC}"
  read -p "지금 업데이트할까요? (Y/n): " DO_UPDATE
  if [[ "$DO_UPDATE" =~ ^[Nn]$ ]]; then
    return
  fi

  if curl -fsSL --max-time 5 "$REPO_RAW/scripts/build-tauri-macos.sh" -o "$0.new"; then
    chmod +x "$0.new"
    mv "$0.new" "$0"
    echo -e "${GREEN}✅ 업데이트 완료 (${remote_version}). 스크립트를 다시 실행합니다...${NC}"
    exec "$0" "$@"
  else
    echo -e "${RED}⚠️  업데이트 다운로드 실패, 기존 버전(${SCRIPT_VERSION})으로 계속합니다.${NC}"
    rm -f "$0.new"
  fi
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

command -v python3 >/dev/null 2>&1 || { echo -e "${RED}❌ python3 이 필요합니다.${NC}"; exit 1; }

APP_NAME=$(python3 -c "import json;print(json.load(open('$CONF'))['productName'])")
CURRENT_VERSION=$(python3 -c "import json;print(json.load(open('$CONF'))['version'])")

echo -e "${CYAN}📦 앱: $APP_NAME  |  현재 버전: $CURRENT_VERSION${NC}"

# ==========================================
# 버전 자동 업데이트 (앱 버전)
# ==========================================

VERSION_NAME="$CURRENT_VERSION"

echo -e "${CYAN}어떤 버전을 올릴까요?${NC}"
echo -e "  ${YELLOW}1) Patch 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')"
echo -e "  ${YELLOW}2) Minor 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')"
echo -e "  ${YELLOW}3) Major 버전 올리기${NC}  → $(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')"
echo -e "  ${YELLOW}4) 버전 유지${NC}"
echo -e "  ${YELLOW}5) 취소${NC}"
read -p "선택 (1-5): " VERSION_CHOICE

case $VERSION_CHOICE in
  1) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}') ;;
  2) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}') ;;
  3) NEW_VERSION=$(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}') ;;
  4) NEW_VERSION="$CURRENT_VERSION"; echo -e "${CYAN}버전 유지: $NEW_VERSION${NC}" ;;
  5) echo -e "${YELLOW}빌드를 취소했습니다.${NC}"; exit 0 ;;
  *) echo -e "${RED}잘못된 선택입니다. 버전을 유지합니다.${NC}"; NEW_VERSION="$CURRENT_VERSION" ;;
esac

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  python3 - "$CONF" "$NEW_VERSION" <<'PYEOF'
import re, sys
path, new_version = sys.argv[1], sys.argv[2]
content = open(path).read()
content = re.sub(r'("version":\s*")[^"]+(")', rf'\g<1>{new_version}\g<2>', content, count=1)
open(path, "w").write(content)
PYEOF
  echo -e "${GREEN}✅ 버전 업데이트: $CURRENT_VERSION → $NEW_VERSION${NC}"
fi

# ==========================================
# 서명 설정 확인 (.env.macos)
# ==========================================

ENV_FILE=".env.macos"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [ -z "$TAURI_SIGN_IDENTITY" ]; then
  echo -e "${RED}❌ TAURI_SIGN_IDENTITY 가 설정되지 않았습니다.${NC}"
  echo -e "${YELLOW}   .env.macos.example 을 복사해서 값을 채워주세요:${NC}"
  echo -e "  cp .env.macos.example .env.macos"
  exit 1
fi

SIGNING_DIR="signing"
PROVISION_PROFILE="${TAURI_PROVISION_PROFILE:-$(find "$SIGNING_DIR" -maxdepth 1 -iname '*.provisionprofile' 2>/dev/null | head -1)}"
ENTITLEMENTS="${TAURI_ENTITLEMENTS:-$(find "$SIGNING_DIR" -maxdepth 1 -iname '*.entitlements' 2>/dev/null | head -1)}"

if [ -z "$PROVISION_PROFILE" ] || [ ! -f "$PROVISION_PROFILE" ]; then
  echo -e "${RED}❌ Provisioning profile 을 찾을 수 없습니다 (signing/*.provisionprofile).${NC}"
  exit 1
fi
if [ -z "$ENTITLEMENTS" ] || [ ! -f "$ENTITLEMENTS" ]; then
  echo -e "${RED}❌ Entitlements 파일을 찾을 수 없습니다 (signing/*.entitlements).${NC}"
  exit 1
fi

if [ -z "$TAURI_INSTALLER_IDENTITY" ]; then
  echo -e "${RED}❌ TAURI_INSTALLER_IDENTITY 가 설정되지 않았습니다 (.env.macos).${NC}"
  exit 1
fi

echo -e "${CYAN}🔑 서명 ID: $TAURI_SIGN_IDENTITY${NC}"
echo -e "${CYAN}📄 Provisioning Profile: $PROVISION_PROFILE${NC}"

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
# 빌드 시작
# ==========================================

BUILD_START_TS=$(date +%s)

echo -e "${BLUE}📥 npm install...${NC}"
if [ -f "package-lock.json" ]; then
  npm ci --no-fund --no-audit
else
  npm install --no-fund --no-audit
fi

if [ "$OBFUSCATE_JS" = "true" ]; then
  echo -e "${BLUE}🚀 [1/4] 프런트엔드 빌드...${NC}"
  npm run build

  echo -e "${YELLOW}🔒 [2/4] JS 난독화 (javascript-obfuscator)...${NC}"
  if ! npx --yes javascript-obfuscator dist --output dist \
    --compact true --control-flow-flattening true --string-array true \
    --string-array-encoding base64 --self-defending true; then
    echo -e "${RED}❌ javascript-obfuscator 실행 실패 — 난독화 안 된 결과가 패키징되지 않도록 중단합니다.${NC}"
    exit 1
  fi

  echo -e "${BLUE}🚀 [3/4] tauri build (프런트엔드 재빌드 스킵)...${NC}"
  npm run tauri build -- --config '{"build":{"beforeBuildCommand":""}}' "$@"
else
  echo -e "${BLUE}🚀 [1/3] tauri build...${NC}"
  npm run tauri build -- "$@"
  echo -e "${CYAN}ℹ️  JS 난독화는 기본 꺼져있음 — 켜려면: TAURI_OBFUSCATE_JS=true bash scripts/build-tauri-macos.sh${NC}"
fi

BUNDLE_APP="src-tauri/target/release/bundle/macos/${APP_NAME}.app"
if [ ! -d "$BUNDLE_APP" ]; then
  echo -e "${RED}❌ 빌드 결과 .app 을 찾을 수 없습니다: $BUNDLE_APP${NC}"
  exit 1
fi

echo -e "${YELLOW}🛡️ Codesigning (Apple Distribution)...${NC}"
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

echo -e "${BLUE}📂 결과 폴더 여는 중...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$SIGNING_DIR/build"
fi

# ==========================================
# 빌드 완료 알림
# ==========================================

BUILD_END_TS=$(date +%s)
BUILD_ELAPSED=$((BUILD_END_TS - BUILD_START_TS))
BUILD_ELAPSED_MIN=$((BUILD_ELAPSED / 60))
BUILD_ELAPSED_SEC=$((BUILD_ELAPSED % 60))
BUILD_ELAPSED_FMT="${BUILD_ELAPSED_MIN}m ${BUILD_ELAPSED_SEC}s"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # 빌드는 이미 성공했으므로 알림 명령 실패로 스크립트 전체가 죽지 않도록 best-effort 처리.
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
  say "Build process completed successfully" 2>/dev/null || true
  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "✅ Build Finished" subtitle (item 2 of argv)' \
    -e 'end run' \
    "Version $NEW_VERSION 빌드 완료 ($BUILD_ELAPSED_FMT)" \
    "$APP_NAME.pkg is ready" 2>/dev/null || true
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version : $NEW_VERSION"
echo -e "📍 Package : $PKG_OUT"
echo -e "⏱️  빌드 시간 : $BUILD_ELAPSED_FMT"
echo -e "------------------------------------------------------------"
echo -e "${CYAN}ℹ️  Transporter 앱으로 $PKG_OUT 를 업로드하면 App Store Connect 에 반영됩니다.${NC}"
