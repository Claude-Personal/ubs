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
# 플랫폼 선택
# ==========================================

echo ""
echo -e "${CYAN}🎯 어떤 플랫폼을 빌드할까요?${NC}"
echo -e "  ${YELLOW}1) iOS + Android 둘 다${NC}"
echo -e "  ${YELLOW}2) iOS만${NC}"
echo -e "  ${YELLOW}3) Android만${NC}"
read -p "선택 (1-3): " PLATFORM_CHOICE

case $PLATFORM_CHOICE in
  1)
    BUILD_IOS=true
    BUILD_ANDROID=true
    echo -e "${GREEN}✅ iOS + Android 빌드${NC}"
    ;;
  2)
    BUILD_IOS=true
    BUILD_ANDROID=false
    echo -e "${GREEN}✅ iOS만 빌드${NC}"
    ;;
  3)
    BUILD_IOS=false
    BUILD_ANDROID=true
    echo -e "${GREEN}✅ Android만 빌드${NC}"
    ;;
  *)
    echo -e "${RED}잘못된 선택입니다. iOS + Android 둘 다 빌드합니다.${NC}"
    BUILD_IOS=true
    BUILD_ANDROID=true
    ;;
esac

# ==========================================
# 환경변수 파일 확인 (--dart-define-from-file)
# ==========================================

ENV_FILE=".env.prod"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE=".env"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ 환경변수 파일이 없습니다 (.env.prod 또는 .env)${NC}"
  echo -e "${YELLOW}  .env.example을 복사해서 값을 채워주세요:${NC}"
  echo -e "  cp .env.example .env"
  exit 1
fi

echo -e "${CYAN}🔑 환경변수: $ENV_FILE${NC}"
DART_DEFINE="--dart-define-from-file=$ENV_FILE"

# ==========================================
# 빌드 시작
# ==========================================

echo -e "${BLUE}🚀 [1/4] Cleaning & Fetching Dependencies...${NC}"
flutter clean
flutter pub get

# 코드 생성 라이브러리(Freezed, Riverpod 등) 사용 시 주석 해제
# echo -e "${BLUE}⚙️ [2/4] Generating Codes (build_runner)...${NC}"
# dart run build_runner build --delete-conflicting-outputs

if [ "$BUILD_ANDROID" = true ]; then
  echo -e "${YELLOW}🛡️ [3/4] Building Android App Bundle (Optimized)...${NC}"
  flutter build appbundle --release \
    $DART_DEFINE \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols \
    --tree-shake-icons \
    --no-pub
fi

if [ "$BUILD_IOS" = true ]; then
  echo -e "${YELLOW}🍎 [4/4] Building iOS IPA (Archive + Export)...${NC}"
  # flutter build ipa: --dart-define 값을 포함하여 Archive까지 Flutter CLI가 직접 처리.
  # Xcode에서 수동 Archive 시 --dart-define이 전달되지 않으므로
  # String.fromEnvironment() 값이 모두 빈 문자열이 되어 흰 화면 버그가 발생함.
  # 반드시 이 스크립트로만 빌드할 것.
  flutter build ipa --release \
    $DART_DEFINE \
    --export-options-plist=ios/ExportOptions.plist \
    --obfuscate \
    --split-debug-info=build/ios/outputs/symbols \
    --no-pub
fi

# ==========================================
# 빌드 완료 알림 + 폴더 열기
# ==========================================

ANDROID_OUT="build/app/outputs/bundle/release"
IOS_OUT="build/ios/ipa"

if [[ "$OSTYPE" == "darwin"* ]]; then
  afplay /System/Library/Sounds/Glass.aiff
  say "Build process completed successfully"
  osascript -e "display notification \"Version $NEW_VERSION 빌드 완료\" with title \"✅ Build Finished\" subtitle \"Deployment files are ready\""

  if [ "$BUILD_ANDROID" = true ]; then
    if [ -d "$ANDROID_OUT" ]; then
      open "$ANDROID_OUT"
    else
      echo -e "${RED}⚠️  Android 출력 폴더를 찾을 수 없습니다: $ANDROID_OUT${NC}"
    fi
  fi

  if [ "$BUILD_IOS" = true ]; then
    if [ -d "$IOS_OUT" ]; then
      open "$IOS_OUT"
    else
      echo -e "${RED}⚠️  iOS 출력 폴더를 찾을 수 없습니다: $IOS_OUT${NC}"
    fi
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [ "$BUILD_ANDROID" = true ]; then
    xdg-open "$ANDROID_OUT" 2>/dev/null || true
  fi

elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
  if [ "$BUILD_ANDROID" = true ]; then
    explorer.exe "$(cygpath -w "$ANDROID_OUT")" 2>/dev/null || true
  fi
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version    : $NEW_VERSION"
if [ "$BUILD_ANDROID" = true ]; then
  echo -e "📍 Android AAB : $ANDROID_OUT/app-release.aab"
fi
if [ "$BUILD_IOS" = true ]; then
  echo -e "📍 iOS IPA     : $IOS_OUT/Runner.ipa"
fi
echo -e "------------------------------------------------------------"
