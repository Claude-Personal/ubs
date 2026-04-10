#!/bin/bash

# =================================================================
# Flutter Production Optimization Build Script
# Description: Automated Build for Android (AAB) & iOS (IPA)
# Features: Obfuscation, Tree-shaking, AOT, Smart Notifications
# =================================================================

set -e # 에러 발생 시 즉시 중단

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
  --no-pub

# ==========================================
# 빌드 완료 알림 로직 (macOS)
# ==========================================
if [[ "$OSTYPE" == "darwin"* ]]; then
  # 사운드 효과
  afplay /System/Library/Sounds/Glass.aiff

  # Siri 음성 안내 (범용 문구)
  say "Build process completed successfully"

  # 시스템 알림 배너
  osascript -e 'display notification "Check build/app/outputs/bundle/release/" with title "✅ Build Finished" subtitle "Deployment files are ready"'
fi

echo -e "------------------------------------------------------------"
echo -e "${GREEN}✅ ALL BUILDS COMPLETED SUCCESSFULLY!${NC}"
echo -e "📍 Android: build/app/outputs/bundle/release/app-release.aab"
echo -e "📍 iOS: build/ios/iphoneos/Runner.app"
echo -e "------------------------------------------------------------"