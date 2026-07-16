#!/bin/bash

# =================================================================
# Universal Build Script - Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main/install.sh | bash
# Detects the project type (Flutter / Tauri) and installs the matching
# build script + dispatcher into the current project.
# =================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main"

echo -e "${CYAN}🚀 Universal Build Script Installer${NC}"
echo -e "------------------------------------------------------------"

# ==========================================
# 프로젝트 타입 자동 감지
# ==========================================

PROJECT_TYPE=""
if [ -f "pubspec.yaml" ]; then
  PROJECT_TYPE="flutter"
  echo -e "${GREEN}✅ Flutter project detected: $(grep '^name:' pubspec.yaml | sed 's/name: //')${NC}"
elif [ -f "src-tauri/tauri.conf.json" ]; then
  PROJECT_TYPE="tauri"
  echo -e "${GREEN}✅ Tauri project detected (src-tauri/tauri.conf.json)${NC}"
else
  echo -e "${RED}❌ No supported project found.${NC}"
  echo -e "${YELLOW}   Run this script from a Flutter project root (pubspec.yaml)${NC}"
  echo -e "${YELLOW}   or a Tauri project root (src-tauri/tauri.conf.json).${NC}"
  exit 1
fi

mkdir -p scripts

# ==========================================
# 공통 디스패처(build.sh) 설치
# ==========================================

if [ -f "build.sh" ]; then
  echo -e "${YELLOW}⚠️  build.sh already exists.${NC}"
  read -p "   Overwrite? (y/N): " OVERWRITE_DISPATCH
  if [[ "$OVERWRITE_DISPATCH" =~ ^[Yy]$ ]]; then
    curl -fsSL "$REPO_RAW/build.sh" -o build.sh
    chmod +x build.sh
    echo -e "${GREEN}✅ Updated: build.sh${NC}"
  fi
else
  curl -fsSL "$REPO_RAW/build.sh" -o build.sh
  chmod +x build.sh
  echo -e "${GREEN}✅ Created: build.sh (auto-detect dispatcher)${NC}"
fi

# ==========================================
# Flutter 전용 설치
# ==========================================

if [ "$PROJECT_TYPE" = "flutter" ]; then
  if [ -f "scripts/build-flutter.sh" ]; then
    echo -e "${YELLOW}⚠️  scripts/build-flutter.sh already exists.${NC}"
    read -p "   Overwrite? (y/N): " OVERWRITE
  else
    OVERWRITE="y"
  fi
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    curl -fsSL "$REPO_RAW/scripts/build-flutter.sh" -o scripts/build-flutter.sh
    chmod +x scripts/build-flutter.sh
    echo -e "${GREEN}✅ Created: scripts/build-flutter.sh${NC}"
  fi

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

  echo -e "\n------------------------------------------------------------"
  echo -e "${GREEN}🎉 Installation complete!${NC}"
  echo -e "------------------------------------------------------------"
  echo -e "  ${YELLOW}1.${NC} Fill in API keys:    ${CYAN}open .env${NC}"
  echo -e "  ${YELLOW}2.${NC} Start building:      ${CYAN}bash build.sh${NC}"
fi

# ==========================================
# Tauri(macOS) 전용 설치
# ==========================================

if [ "$PROJECT_TYPE" = "tauri" ]; then
  if [ -f "scripts/build-tauri-macos.sh" ]; then
    echo -e "${YELLOW}⚠️  scripts/build-tauri-macos.sh already exists.${NC}"
    read -p "   Overwrite? (y/N): " OVERWRITE
  else
    OVERWRITE="y"
  fi
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    curl -fsSL "$REPO_RAW/scripts/build-tauri-macos.sh" -o scripts/build-tauri-macos.sh
    chmod +x scripts/build-tauri-macos.sh
    echo -e "${GREEN}✅ Created: scripts/build-tauri-macos.sh${NC}"
  fi

  if [ ! -f ".env.macos.example" ]; then
    curl -fsSL "$REPO_RAW/.env.macos.example" -o .env.macos.example
    echo -e "${GREEN}✅ Created: .env.macos.example${NC}"
  fi

  if [ ! -f ".env.macos" ]; then
    cp .env.macos.example .env.macos
    echo -e "${GREEN}✅ Created: .env.macos (from .env.macos.example)${NC}"
    echo -e "${YELLOW}⚠️  Open .env.macos and add your codesign identities before building.${NC}"
  fi

  mkdir -p signing
  echo -e "${CYAN}ℹ️  signing/ 폴더에 *.provisionprofile, *.entitlements 파일을 넣어주세요.${NC}"

  # 서명 identity·프로파일이 실수로 커밋되지 않도록 .gitignore에 등록
  if [ -f ".gitignore" ] && ! grep -q "^signing/$" .gitignore; then
    printf '\n# Universal-Build-Script (Tauri macOS)\nsigning/\n.env.macos\n' >> .gitignore
    echo -e "${GREEN}✅ .gitignore에 signing/, .env.macos 추가${NC}"
  elif [ ! -f ".gitignore" ]; then
    printf '# Universal-Build-Script (Tauri macOS)\nsigning/\n.env.macos\n' > .gitignore
    echo -e "${GREEN}✅ Created: .gitignore (signing/, .env.macos)${NC}"
  fi
  chmod 600 .env.macos 2>/dev/null || true

  echo -e "\n------------------------------------------------------------"
  echo -e "${GREEN}🎉 Installation complete!${NC}"
  echo -e "------------------------------------------------------------"
  echo -e "  ${YELLOW}1.${NC} Fill in signing identities: ${CYAN}open .env.macos${NC}"
  echo -e "  ${YELLOW}2.${NC} Add provisioning profile + entitlements to ${CYAN}signing/${NC}"
  echo -e "  ${YELLOW}3.${NC} Start building:              ${CYAN}bash build.sh${NC}"
fi

echo -e "------------------------------------------------------------"
