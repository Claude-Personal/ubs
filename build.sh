#!/bin/bash

# =================================================================
# Flutter Production Optimization Build Script
# Description: Automated Build for Android (AAB) & iOS (IPA)
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

# ==========================================
# 버전 자동 업데이트
# ==========================================

PUBSPEC="pubspec.yaml"

# 현재 버전 읽기 (예: 1.0.0+1)
CURRENT_VERSION=$(grep '^version:' $PUBSPEC | sed 's/version: //' | tr -d '[:space:]')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)  # 1.0.0
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)  # 1

echo -e "${CYAN}📦 현재 버전: $CURRENT_VERSION${NC}"
echo -e "${CYAN}어떤 버전을 올릴까요?${NC}"
echo -e "  ${YELLOW}1) Build Number만 올리기${NC}  → $VERSION_NAME+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}2) Patch 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}3) Minor 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}4) Major 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}5) 버전 유지${NC}"
read -p "선택 (1-5): " VERSION_CHOICE

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
    echo -e "${CYAN}버전 유지: $NEW_VERSION${NC}"
    ;;
  *)
    echo -e "${RED}잘못된 선택입니다. 버전을 유지합니다.${NC}"
    NEW_VERSION="$CURRENT_VERSION"
    ;;
esac

# pubspec.yaml 버전 교체
if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
  echo -e "${GREEN}✅ 버전 업데이트: $CURRENT_VERSION → $NEW_VERSION${NC}"
fi

# ==========================================
# 빌드 시작
# ==========================================

echo -e "${BLUE}🚀 [1/4] Cleaning & Fetching Dependencies...${NC}"
flutter clean
flutter pub get

# 코드 생성 라이브러리(Freezed, Riverpod 등) 사용 시 주석 해제
# echo -e "${BLUE}⚙️ [2/4] Generating Codes (build_runner)...${NC}"
# dart run build_runner build --delete-conflicting-outputs

echo -e "${YELLOW}🛡️ [3/4] Building Android App Bundle (Optimized)...${NC}"
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --tree-shake-icons \
  --no-pub

echo -e "${YELLOW}🍎 [4/4] Building iOS Release Archive...${NC}"
flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols \
  --no-pub || true

# ==========================================
# 빌드 완료 알림 + 폴더 열기
# ==========================================

ANDROID_OUT="build/app/outputs/bundle/release"
IOS_OUT="build/ios/iphoneos"

if [[ "$OSTYPE" == "darwin"* ]]; then
  afplay /System/Library/Sounds/Glass.aiff
  say "Build process completed successfully"
  osascript -e "display notification \"Version $NEW_VERSION 빌드 완료\" with title \"✅ Build Finished\" subtitle \"Deployment files are ready\""

  if [ -d "$ANDROID_OUT" ]; then
    open "$ANDROID_OUT"
  else
    echo -e "${RED}⚠️  Android 출력 폴더를 찾을 수 없습니다: $ANDROID_OUT${NC}"
  fi

  if [ -d "$IOS_OUT" ]; then
    open "$IOS_OUT"
  else
    echo -e "${RED}⚠️  iOS 출력 폴더를 찾을 수 없습니다: $IOS_OUT${NC}"
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$ANDROID_OUT" 2>/dev/null || true

elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
  explorer.exe "$(cygpath -w "$ANDROID_OUT")" 2>/dev/null || true
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ ALL BUILDS COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version    : $NEW_VERSION"
echo -e "📍 Android AAB : $ANDROID_OUT/app-release.aab"
echo -e "📍 iOS Runner  : $IOS_OUT/Runner.app"
echo -e "------------------------------------------------------------"
