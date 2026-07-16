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

SCRIPT_VERSION="1.0.0"
REPO_RAW="https://raw.githubusercontent.com/kimdzhekhon/Flutter-Optimization-Build-Script/main"

check_script_update() {
  local remote_version
  remote_version=$(curl -fsSL --max-time 3 "$REPO_RAW/TAURI_VERSION" 2>/dev/null | tr -d '[:space:]')
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

  if curl -fsSL --max-time 5 "$REPO_RAW/build-tauri-macos.sh" -o "$0.new"; then
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

echo -e "${CYAN}🔑 서명 ID: $TAURI_SIGN_IDENTITY${NC}"
echo -e "${CYAN}📄 Provisioning Profile: $PROVISION_PROFILE${NC}"

# ==========================================
# 빌드 시작
# ==========================================

BUILD_START_TS=$(date +%s)

echo -e "${BLUE}🚀 [1/4] npm install & tauri build...${NC}"
npm install --no-fund --no-audit >/dev/null 2>&1 || true
npm run tauri build

BUNDLE_APP="src-tauri/target/release/bundle/macos/${APP_NAME}.app"
if [ ! -d "$BUNDLE_APP" ]; then
  echo -e "${RED}❌ 빌드 결과 .app 을 찾을 수 없습니다: $BUNDLE_APP${NC}"
  exit 1
fi

echo -e "${YELLOW}🛡️ [2/4] Codesigning (Apple Distribution)...${NC}"
cp "$PROVISION_PROFILE" "$BUNDLE_APP/Contents/embedded.provisionprofile"
codesign --deep --force --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$TAURI_SIGN_IDENTITY" \
  "$BUNDLE_APP"
codesign --verify --deep --strict --verbose=2 "$BUNDLE_APP"

echo -e "${YELLOW}📦 [3/4] Building signed installer package (.pkg)...${NC}"
if [ -z "$TAURI_INSTALLER_IDENTITY" ]; then
  echo -e "${RED}❌ TAURI_INSTALLER_IDENTITY 가 설정되지 않았습니다 (.env.macos).${NC}"
  exit 1
fi

mkdir -p "$SIGNING_DIR/build"
PKG_OUT="$SIGNING_DIR/build/${APP_NAME}.pkg"
productbuild --component "$BUNDLE_APP" /Applications \
  --sign "$TAURI_INSTALLER_IDENTITY" \
  "$PKG_OUT"

echo -e "${BLUE}📂 [4/4] Opening output folder...${NC}"
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
  afplay /System/Library/Sounds/Glass.aiff
  say "Build process completed successfully"
  osascript -e "display notification \"Version $NEW_VERSION 빌드 완료 ($BUILD_ELAPSED_FMT)\" with title \"✅ Build Finished\" subtitle \"$APP_NAME.pkg is ready\""
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version : $NEW_VERSION"
echo -e "📍 Package : $PKG_OUT"
echo -e "⏱️  빌드 시간 : $BUILD_ELAPSED_FMT"
echo -e "------------------------------------------------------------"
echo -e "${CYAN}ℹ️  Transporter 앱으로 $PKG_OUT 를 업로드하면 App Store Connect 에 반영됩니다.${NC}"
