#!/bin/bash

# =================================================================
# Flutter Production Optimization Build Script
# Description: Automated Build for Android (AAB/APK), iOS (IPA), and Web
# Features: Obfuscation, Tree-shaking, AOT, Smart Notifications, Auto Version Bump
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
source "$SCRIPT_DIR/lib/i18n.sh"

# ==========================================
# 빌드 스크립트 자체 업데이트 확인
# ==========================================

check_script_update() {
  [ "${UBS_ALLOW_SELF_UPDATE:-false}" = "true" ] || return 0
  echo -e "${YELLOW}$(ubs_msg SELF_UPDATE_DEPRECATED)${NC}" >&2
}

check_script_update "$@"

# ==========================================
# 버전 자동 업데이트 (앱 버전)
# ==========================================

PUBSPEC="pubspec.yaml"

# 현재 버전 읽기 (예: 1.0.0+1)
CURRENT_VERSION=$(grep '^version:' $PUBSPEC | sed 's/version: //' | tr -d '[:space:]')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)  # 1.0.0
case "$CURRENT_VERSION" in
  *+*) BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2) ;;
  *) BUILD_NUMBER=0 ;;
esac

VERSION_CHANGED=false
BUILD_COMPLETED=false

set_pubspec_version() {
  local version="$1"
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^version: .*/version: $version/" "$PUBSPEC"
  else
    sed -i "s/^version: .*/version: $version/" "$PUBSPEC"
  fi
}

restore_version_if_incomplete() {
  if [ "$VERSION_CHANGED" = true ] && [ "$BUILD_COMPLETED" != true ]; then
    set_pubspec_version "$CURRENT_VERSION"
    echo -e "${YELLOW}↩️  $(ubs_msg VERSION_RESTORE_ON_FAIL "$CURRENT_VERSION")${NC}" >&2
  fi
}
trap restore_version_if_incomplete EXIT

echo -e "${CYAN}📦 $(ubs_msg CURRENT_VERSION_LABEL "$CURRENT_VERSION")${NC}"
if [ "${UBS_NON_INTERACTIVE:-false}" = "true" ]; then
  case "${UBS_VERSION_BUMP:-none}" in
    build) VERSION_CHOICE=1 ;;
    patch) VERSION_CHOICE=2 ;;
    minor) VERSION_CHOICE=3 ;;
    major) VERSION_CHOICE=4 ;;
    none) VERSION_CHOICE=5 ;;
    *) echo -e "${RED}$(ubs_msg UNSUPPORTED_VERSION_BUMP)${NC}" >&2; exit 2 ;;
  esac
  echo -e "${CYAN}$(ubs_msg NONINTERACTIVE_VERSION_POLICY "${UBS_VERSION_BUMP:-none}")${NC}"
else
  echo -e "${CYAN}$(ubs_msg MENU_VERSION_PROMPT)${NC}"
  NEXT_BUILD="$VERSION_NAME+$((BUILD_NUMBER + 1))"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_BUILD_NUMBER_BUMP)${NC}  → ${NEXT_BUILD}"
  NEXT_PATCH="$(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')+$((BUILD_NUMBER + 1))"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_PATCH_BUMP)${NC}      → ${NEXT_PATCH}"
  NEXT_MINOR="$(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')+$((BUILD_NUMBER + 1))"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_MINOR_BUMP)${NC}      → ${NEXT_MINOR}"
  NEXT_MAJOR="$(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')+$((BUILD_NUMBER + 1))"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_MAJOR_BUMP)${NC}      → ${NEXT_MAJOR}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_VERSION_KEEP)${NC}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_CANCEL_VERSION)${NC}"
  read -p "$(ubs_msg CHOICE_PROMPT_1_6)" VERSION_CHOICE
fi

case $VERSION_CHOICE in
  1)
    NEW_VERSION="$VERSION_NAME+$((BUILD_NUMBER + 1))"
    ;;
  2)
    NEW_PATCH=$(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')
    NEW_VERSION="$NEW_PATCH+$((BUILD_NUMBER + 1))"
    ;;
  3)
    NEW_MINOR=$(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')
    NEW_VERSION="$NEW_MINOR+$((BUILD_NUMBER + 1))"
    ;;
  4)
    NEW_MAJOR=$(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')
    NEW_VERSION="$NEW_MAJOR+$((BUILD_NUMBER + 1))"
    ;;
  5)
    NEW_VERSION="$CURRENT_VERSION"
    echo -e "${CYAN}$(ubs_msg VERSION_KEEP_LABEL "$NEW_VERSION")${NC}"
    ;;
  6)
    echo -e "${YELLOW}$(ubs_msg BUILD_CANCELLED)${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}$(ubs_msg INVALID_CHOICE_KEEP_VERSION)${NC}"
    NEW_VERSION="$CURRENT_VERSION"
    ;;
esac

# pubspec.yaml 버전 교체
if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  set_pubspec_version "$NEW_VERSION"
  VERSION_CHANGED=true
  echo -e "${GREEN}✅ $(ubs_msg VERSION_UPDATED "$CURRENT_VERSION" "$NEW_VERSION")${NC}"
fi

# ==========================================
# 플랫폼 선택
# ==========================================

echo ""
BUILD_ANDROID=false
BUILD_APK=false
BUILD_IOS=false
BUILD_WEB=false
CUSTOM_OUTPUTS="${UBS_FLUTTER_OUTPUTS:-auto}"

if [ "$CUSTOM_OUTPUTS" != "auto" ]; then
  if ! printf '%s\n' "$CUSTOM_OUTPUTS" | grep -Eqs '^(appbundle|apk|ipa|web)(,(appbundle|apk|ipa|web))*$'; then
    echo -e "${RED}$(ubs_msg UNSUPPORTED_FLUTTER_OUTPUTS "$CUSTOM_OUTPUTS")${NC}" >&2
    exit 2
  fi
  OLD_IFS="$IFS"
  IFS=','
  for output in $CUSTOM_OUTPUTS; do
    case "$output" in
      appbundle) BUILD_ANDROID=true ;;
      apk) BUILD_APK=true ;;
      ipa) BUILD_IOS=true ;;
      web) BUILD_WEB=true ;;
      *) echo -e "${RED}$(ubs_msg UNSUPPORTED_FLUTTER_OUTPUTS "$output")${NC}" >&2; exit 2 ;;
    esac
  done
  IFS="$OLD_IFS"
  echo -e "${CYAN}$(ubs_msg FLUTTER_OUTPUTS_SPECIFIED "$CUSTOM_OUTPUTS")${NC}"
elif [ "${UBS_NON_INTERACTIVE:-false}" = "true" ]; then
  case "${UBS_FLUTTER_PLATFORM:-auto}" in
    auto)
      if [ "$(uname -s)" = "Darwin" ]; then PLATFORM_CHOICE=1
      else PLATFORM_CHOICE=3
      fi
      ;;
    all) PLATFORM_CHOICE=1 ;;
    ios) PLATFORM_CHOICE=2 ;;
    android) PLATFORM_CHOICE=3 ;;
    *) echo -e "${RED}$(ubs_msg UNSUPPORTED_FLUTTER_PLATFORM)${NC}" >&2; exit 2 ;;
  esac
  echo -e "${CYAN}$(ubs_msg NONINTERACTIVE_FLUTTER_PLATFORM "${UBS_FLUTTER_PLATFORM:-auto}")${NC}"
else
  echo -e "${CYAN}🎯 $(ubs_msg MENU_PLATFORM_PROMPT)${NC}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_PLATFORM_BOTH)${NC}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_PLATFORM_IOS)${NC}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_PLATFORM_ANDROID)${NC}"
  echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_CANCEL_PLATFORM)${NC}"
  read -p "$(ubs_msg CHOICE_PROMPT_1_4)" PLATFORM_CHOICE
fi

if [ "$CUSTOM_OUTPUTS" = "auto" ]; then
case $PLATFORM_CHOICE in
  1)
    BUILD_IOS=true
    BUILD_ANDROID=true
    echo -e "${GREEN}✅ $(ubs_msg PLATFORM_SELECTED_BOTH)${NC}"
    ;;
  2)
    BUILD_IOS=true
    BUILD_ANDROID=false
    echo -e "${GREEN}✅ $(ubs_msg PLATFORM_SELECTED_IOS)${NC}"
    ;;
  3)
    BUILD_IOS=false
    BUILD_ANDROID=true
    echo -e "${GREEN}✅ $(ubs_msg PLATFORM_SELECTED_ANDROID)${NC}"
    ;;
  4)
    echo -e "${YELLOW}$(ubs_msg BUILD_CANCELLED)${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}$(ubs_msg INVALID_CHOICE_BOTH)${NC}"
    BUILD_IOS=true
    BUILD_ANDROID=true
    ;;
esac
fi

PARALLEL_BUILD=false
PARALLEL_PREFS_FILE="$SCRIPT_DIR/.build_prefs"

if [ "$BUILD_IOS" = true ] && [ "$BUILD_ANDROID" = true ] && \
   [ "${UBS_NON_INTERACTIVE:-false}" != "true" ]; then
  if [ -f "$PARALLEL_PREFS_FILE" ]; then
    source "$PARALLEL_PREFS_FILE"
    if [ "$PARALLEL_BUILD" = true ]; then
      echo -e "${CYAN}$(ubs_msg PARALLEL_PREF_SAVED_PARALLEL)${NC} $(ubs_msg PARALLEL_PREF_CHANGE_HINT "$PARALLEL_PREFS_FILE")"
    else
      echo -e "${CYAN}$(ubs_msg PARALLEL_PREF_SAVED_SEQUENTIAL)${NC} $(ubs_msg PARALLEL_PREF_CHANGE_HINT "$PARALLEL_PREFS_FILE")"
    fi
  else
    echo -e "${CYAN}$(ubs_msg PARALLEL_CHOICE_PROMPT)${NC}"
    echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_SEQUENTIAL)${NC}"
    echo -e "  ${YELLOW}$(ubs_msg MENU_OPT_CONCURRENT)${NC} $(ubs_msg MENU_OPT_CONCURRENT_WARNING)"
    read -p "$(ubs_msg CHOICE_PROMPT_1_2)" PARALLEL_CHOICE
    if [ "$PARALLEL_CHOICE" = "2" ]; then
      PARALLEL_BUILD=true
      echo -e "${GREEN}✅ $(ubs_msg PARALLEL_CHOSEN_CONCURRENT)${NC}"
    else
      PARALLEL_BUILD=false
      echo -e "${GREEN}✅ $(ubs_msg PARALLEL_CHOSEN_SEQUENTIAL)${NC}"
    fi
    echo "PARALLEL_BUILD=$PARALLEL_BUILD" > "$PARALLEL_PREFS_FILE"
    echo -e "${CYAN}ℹ️  $(ubs_msg PARALLEL_PREF_SAVE_NOTICE "$PARALLEL_PREFS_FILE")${NC}"
  fi
fi

# ==========================================
# 환경변수 파일 확인 (--dart-define-from-file)
# ==========================================

ENV_FILE=".env.prod"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env"
fi

if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=""
  DART_DEFINE=""
  echo -e "${CYAN}ℹ️  $(ubs_msg ENV_FILE_MISSING)${NC}"
else
  echo -e "${CYAN}🔑 $(ubs_msg ENV_FILE_LABEL "$ENV_FILE")${NC}"
  DART_DEFINE="--dart-define-from-file=$ENV_FILE"
fi
ANDROID_OUT="build/app/outputs/bundle/release"
APK_OUT="build/app/outputs/flutter-apk"
IOS_OUT="build/ios/ipa"
WEB_OUT="build/web"

# ==========================================
# 빌드 시작
# ==========================================

BUILD_START_TS=$(date +%s)

echo -e "${BLUE}🚀 [1/4] $(ubs_msg STEP_CLEAN_FETCH)${NC}"
if [ "${UBS_SKIP_CLEAN:-false}" != "true" ]; then
  flutter clean
else
  echo -e "${CYAN}ℹ️  $(ubs_msg SKIP_CLEAN_NOTICE)${NC}"
fi
flutter pub get

# 코드 생성 라이브러리(Freezed, Riverpod 등) 사용 시 주석 해제
# echo -e "${BLUE}⚙️ [2/4] Generating Codes (build_runner)...${NC}"
# dart run build_runner build --delete-conflicting-outputs

build_android() {
  echo -e "${YELLOW}🛡️ [3/4] $(ubs_msg STEP_BUILD_ANDROID)${NC}"
  flutter build appbundle --release \
    $DART_DEFINE \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols \
    --tree-shake-icons \
    --no-pub
}

build_apk() {
  echo -e "${YELLOW}🤖 $(ubs_msg STEP_BUILD_APK)${NC}"
  flutter build apk --release \
    $DART_DEFINE \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols \
    --tree-shake-icons \
    --split-per-abi \
    --no-pub
}

build_ios() {
  local export_options="${UBS_IOS_EXPORT_OPTIONS:-ios/ExportOptions.plist}"
  if [ ! -f "$export_options" ] && [ -f "${UBS_RUNTIME_ROOT:-}/templates/flutter/ExportOptions.plist" ]; then
    export_options="${UBS_RUNTIME_ROOT}/templates/flutter/ExportOptions.plist"
    echo -e "${CYAN}ℹ️  $(ubs_msg EXPORT_OPTIONS_FALLBACK)${NC}"
  fi
  [ -f "$export_options" ] || {
    echo -e "${RED}❌ $(ubs_msg EXPORT_OPTIONS_NOT_FOUND "$export_options")${NC}" >&2
    return 1
  }
  echo -e "${YELLOW}🍎 [4/4] $(ubs_msg STEP_BUILD_IOS)${NC}"
  # flutter build ipa: --dart-define 값을 포함하여 Archive까지 Flutter CLI가 직접 처리.
  # Xcode에서 수동 Archive 시 --dart-define이 전달되지 않으므로
  # String.fromEnvironment() 값이 모두 빈 문자열이 되어 흰 화면 버그가 발생함.
  # 반드시 이 스크립트로만 빌드할 것.
  flutter build ipa --release \
    $DART_DEFINE \
    --export-options-plist="$export_options" \
    --obfuscate \
    --split-debug-info=build/ios/outputs/symbols \
    --no-pub
}

build_web() {
  echo -e "${YELLOW}🌐 $(ubs_msg STEP_BUILD_WEB)${NC}"
  flutter build web --release \
    $DART_DEFINE \
    --tree-shake-icons \
    --no-pub
}

if [ "$PARALLEL_BUILD" = true ] && [ "$BUILD_ANDROID" = true ] && [ "$BUILD_IOS" = true ]; then
  echo -e "${BLUE}⏱️  $(ubs_msg PARALLEL_BUILD_START)${NC}"
  build_android &
  ANDROID_PID=$!
  build_ios &
  IOS_PID=$!

  if wait "$ANDROID_PID"; then ANDROID_STATUS=0; else ANDROID_STATUS=$?; fi
  if wait "$IOS_PID"; then IOS_STATUS=0; else IOS_STATUS=$?; fi

  if [ "$ANDROID_STATUS" -ne 0 ] || [ "$IOS_STATUS" -ne 0 ]; then
    echo -e "${RED}❌ $(ubs_msg PARALLEL_BUILD_FAILED "$ANDROID_STATUS" "$IOS_STATUS")${NC}"
    exit 1
  fi
else
  [ "$BUILD_ANDROID" = true ] && build_android
  [ "$BUILD_IOS" = true ] && build_ios
fi
[ "$BUILD_APK" = true ] && build_apk
[ "$BUILD_WEB" = true ] && build_web
BUILD_COMPLETED=true

# ==========================================
# 버전 변경 커밋 (안 하면 uncommitted diff로 계속 쌓임 — #26)
# ==========================================

if [ "$VERSION_CHANGED" = true ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add -- "$PUBSPEC" 2>/dev/null
    if git commit -m "chore: 버전 ${NEW_VERSION}" -- "$PUBSPEC" >/dev/null 2>&1; then
      echo -e "${GREEN}✅ $(ubs_msg VERSION_COMMIT_SUCCESS "$NEW_VERSION")${NC}"
    else
      echo -e "${YELLOW}⚠️  $(ubs_msg VERSION_COMMIT_FAILED "$NEW_VERSION")${NC}" >&2
    fi
  else
    echo -e "${YELLOW}⚠️  $(ubs_msg VERSION_COMMIT_NOT_GIT_REPO "$NEW_VERSION")${NC}" >&2
  fi
fi

# ==========================================
# 빌드 완료 알림 (결과 폴더는 Python 오케스트레이터가 전체 빌드 종료 후 연다.)
# ==========================================

BUILD_END_TS=$(date +%s)
BUILD_ELAPSED=$((BUILD_END_TS - BUILD_START_TS))
BUILD_ELAPSED_MIN=$((BUILD_ELAPSED / 60))
BUILD_ELAPSED_SEC=$((BUILD_ELAPSED % 60))
BUILD_ELAPSED_FMT="${BUILD_ELAPSED_MIN}m ${BUILD_ELAPSED_SEC}s"

if [[ "$OSTYPE" == "darwin"* ]] && [ "${UBS_NO_NOTIFY:-false}" != "true" ]; then
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
  say "$(ubs_msg NOTIFY_TTS_BUILD_COMPLETE)" 2>/dev/null || true
  osascript -e "display notification \"$(ubs_msg NOTIFY_BUILD_DONE "$NEW_VERSION" "$BUILD_ELAPSED_FMT")\" with title \"✅ $(ubs_msg NOTIFY_TITLE_BUILD_FINISHED)\" subtitle \"$(ubs_msg NOTIFY_SUBTITLE_DEPLOYMENT_READY)\"" 2>/dev/null || true
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ $(ubs_msg BUILD_SUCCESS)${NC}"
echo -e "🏷️  $(ubs_msg BUILD_SUMMARY_VERSION "$NEW_VERSION")"
if [ "$BUILD_ANDROID" = true ]; then
  echo -e "📍 $(ubs_msg BUILD_SUMMARY_ANDROID_AAB "$ANDROID_OUT/app-release.aab")"
fi
if [ "$BUILD_IOS" = true ]; then
  echo -e "📍 $(ubs_msg BUILD_SUMMARY_IOS_IPA "$IOS_OUT/Runner.ipa")"
fi
if [ "$BUILD_APK" = true ]; then
  echo -e "📍 $(ubs_msg BUILD_SUMMARY_ANDROID_APK "$APK_OUT")"
fi
if [ "$BUILD_WEB" = true ]; then
  echo -e "📍 $(ubs_msg BUILD_SUMMARY_FLUTTER_WEB "$WEB_OUT")"
fi
if [ "$PARALLEL_BUILD" = true ]; then BUILD_MODE_LABEL="$(ubs_msg BUILD_MODE_PARALLEL)"; else BUILD_MODE_LABEL="$(ubs_msg BUILD_MODE_SEQUENTIAL)"; fi
echo -e "⏱️  $(ubs_msg BUILD_SUMMARY_ELAPSED "$BUILD_ELAPSED_FMT" "$BUILD_MODE_LABEL")"
echo -e "------------------------------------------------------------"
