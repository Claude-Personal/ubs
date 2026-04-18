#!/bin/bash

# =================================================================
# Flutter Optimization Build Script - Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Flutter-Optimization-Build-Script/main/install.sh | bash
# =================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Flutter Optimization Build Script Installer${NC}"
echo -e "------------------------------------------------------------"

# Flutter 프로젝트인지 확인
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ pubspec.yaml not found.${NC}"
  echo -e "${YELLOW}   Run this script from the root of your Flutter project.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Flutter project detected: $(grep '^name:' pubspec.yaml | sed 's/name: //')${NC}"

# scripts/ 폴더 생성
mkdir -p scripts

# ==========================================
# build.sh 생성
# ==========================================

if [ -f "scripts/build.sh" ]; then
  echo -e "${YELLOW}⚠️  scripts/build.sh already exists.${NC}"
  read -p "   Overwrite? (y/N): " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Skipped build.sh${NC}"
    SKIP_BUILD=true
  fi
fi

if [ "$SKIP_BUILD" != true ]; then
cat > scripts/build.sh << 'BUILDSCRIPT'
#!/bin/bash

# =================================================================
# Flutter Production Optimization Build Script
# Description: Automated Build for Android (AAB) & iOS (IPA)
# Features: Obfuscation, Tree-shaking, AOT, Smart Notifications, Auto Version Bump
# =================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PUBSPEC="pubspec.yaml"

CURRENT_VERSION=$(grep '^version:' $PUBSPEC | sed 's/version: //' | tr -d '[:space:]')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

echo -e "${CYAN}📦 현재 버전: $CURRENT_VERSION${NC}"
echo -e "${CYAN}어떤 버전을 올릴까요?${NC}"
echo -e "  ${YELLOW}1) Build Number만 올리기${NC}  → $VERSION_NAME+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}2) Patch 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1"."$2"."$3+1}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}3) Minor 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1"."$2+1".0"}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}4) Major 버전 올리기${NC}      → $(echo $VERSION_NAME | awk -F. '{print $1+1".0.0"}')+$((BUILD_NUMBER + 1))"
echo -e "  ${YELLOW}5) 버전 유지${NC}"
read -p "선택 (1-5): " VERSION_CHOICE

case $VERSION_CHOICE in
  1) NEW_VERSION="$VERSION_NAME+$((BUILD_NUMBER + 1))" ;;
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

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC
  echo -e "${GREEN}✅ 버전 업데이트: $CURRENT_VERSION → $NEW_VERSION${NC}"
fi

echo ""
echo -e "${CYAN}🎯 어떤 플랫폼을 빌드할까요?${NC}"
echo -e "  ${YELLOW}1) iOS + Android 둘 다${NC}"
echo -e "  ${YELLOW}2) iOS만${NC}"
echo -e "  ${YELLOW}3) Android만${NC}"
read -p "선택 (1-3): " PLATFORM_CHOICE

case $PLATFORM_CHOICE in
  1) BUILD_IOS=true;  BUILD_ANDROID=true  ;;
  2) BUILD_IOS=true;  BUILD_ANDROID=false ;;
  3) BUILD_IOS=false; BUILD_ANDROID=true  ;;
  *) BUILD_IOS=true;  BUILD_ANDROID=true  ;;
esac

ENV_FILE=".env.prod"
if [ ! -f "$ENV_FILE" ]; then ENV_FILE=".env"; fi

if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}❌ 환경변수 파일이 없습니다 (.env.prod 또는 .env)${NC}"
  echo -e "${YELLOW}  cp .env.example .env${NC}"
  exit 1
fi

echo -e "${CYAN}🔑 환경변수: $ENV_FILE${NC}"
DART_DEFINE="--dart-define-from-file=$ENV_FILE"

echo -e "${BLUE}🚀 [1/4] Cleaning & Fetching Dependencies...${NC}"
flutter clean
flutter pub get

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
  flutter build ipa --release \
    $DART_DEFINE \
    --export-options-plist=ios/ExportOptions.plist \
    --obfuscate \
    --split-debug-info=build/ios/outputs/symbols \
    --no-pub
fi

ANDROID_OUT="build/app/outputs/bundle/release"
IOS_OUT="build/ios/ipa"

if [[ "$OSTYPE" == "darwin"* ]]; then
  afplay /System/Library/Sounds/Glass.aiff
  say "Build process completed successfully"
  osascript -e "display notification \"Version $NEW_VERSION 빌드 완료\" with title \"✅ Build Finished\" subtitle \"Deployment files are ready\""
  [ "$BUILD_ANDROID" = true ] && [ -d "$ANDROID_OUT" ] && open "$ANDROID_OUT"
  [ "$BUILD_IOS" = true ]     && [ -d "$IOS_OUT" ]     && open "$IOS_OUT"
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "🏷️  Version    : $NEW_VERSION"
[ "$BUILD_ANDROID" = true ] && echo -e "📍 Android AAB : $ANDROID_OUT/app-release.aab"
[ "$BUILD_IOS" = true ]     && echo -e "📍 iOS IPA     : $IOS_OUT/Runner.ipa"
echo -e "------------------------------------------------------------"
BUILDSCRIPT

  chmod +x scripts/build.sh
  echo -e "${GREEN}✅ Created: scripts/build.sh${NC}"
fi

# ==========================================
# .env.example 생성
# ==========================================

if [ ! -f ".env.example" ]; then
cat > .env.example << 'EOF'
# Copy this file to .env and fill in your values.
# ANTHROPIC_API_KEY=your_key_here
EOF
  echo -e "${GREEN}✅ Created: .env.example${NC}"
fi

if [ ! -f ".env" ] && [ ! -f ".env.prod" ]; then
  cp .env.example .env
  echo -e "${GREEN}✅ Created: .env (from .env.example)${NC}"
  echo -e "${YELLOW}⚠️  Open .env and add your API keys before building.${NC}"
fi

# ==========================================
# ios/ExportOptions.plist 생성
# ==========================================

if [ -d "ios" ] && [ ! -f "ios/ExportOptions.plist" ]; then
cat > ios/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>uploadBitcode</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
EOF
  echo -e "${GREEN}✅ Created: ios/ExportOptions.plist${NC}"
  echo -e "${YELLOW}⚠️  Update ios/ExportOptions.plist with your Team ID for App Store uploads.${NC}"
fi

# ==========================================
# 완료
# ==========================================

echo -e "\n------------------------------------------------------------"
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo -e "------------------------------------------------------------"
echo -e ""
echo -e "  ${YELLOW}1.${NC} Fill in API keys:    ${CYAN}open .env${NC}"
echo -e "  ${YELLOW}2.${NC} Start building:      ${CYAN}bash scripts/build.sh${NC}"
echo -e ""
