#!/usr/bin/env bash

# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main/install.sh | bash
# 기존 UBS 파일까지 갱신하려면:
#   curl -fsSL .../install.sh | UBS_FORCE=true bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main"
FORCE="${UBS_FORCE:-false}"
MANAGE_GITIGNORE="${UBS_MANAGE_GITIGNORE:-true}"

echo -e "${CYAN}🚀 Universal Build Script Installer${NC}"
echo "------------------------------------------------------------"

PROJECT_TYPE="workspace"
if [ -f "src-tauri/tauri.conf.json" ]; then
  PROJECT_TYPE="tauri"
elif [ -f "pubspec.yaml" ] && grep -Eqs 'sdk:[[:space:]]*flutter|^[[:space:]]*flutter:' pubspec.yaml; then
  PROJECT_TYPE="flutter"
elif [ -f "gradlew" ] || [ -f "settings.gradle" ] || [ -f "settings.gradle.kts" ]; then
  PROJECT_TYPE="gradle"
elif [ -f "package.json" ] && grep -Eqs '"build"[[:space:]]*:' package.json; then
  PROJECT_TYPE="node"
fi
echo -e "${GREEN}✅ 설치 위치 타입: $PROJECT_TYPE${NC}"

install_file() {
  local relative="$1"
  local destination="$relative"
  local current="." component old_ifs install_tmp

  old_ifs="$IFS"
  IFS='/'
  for component in $relative; do
    current="$current/$component"
    if [ -L "$current" ]; then
      IFS="$old_ifs"
      echo -e "${RED}거부: 심볼릭 링크 설치 경로 $relative${NC}" >&2
      return 1
    fi
  done
  IFS="$old_ifs"

  if [ -f "$destination" ] && [ "$FORCE" != "true" ]; then
    echo -e "${YELLOW}유지: $destination (갱신하려면 UBS_FORCE=true)${NC}"
    return
  fi

  mkdir -p "$(dirname "$destination")"
  install_tmp="$(mktemp "$destination.ubs-install.XXXXXX")"
  if ! curl -fsSL "$REPO_RAW/$relative" -o "$install_tmp"; then
    rm -f "$install_tmp"
    return 1
  fi
  case "$destination" in *.sh) chmod +x "$install_tmp" ;; esac
  mv -f "$install_tmp" "$destination"
  echo -e "${GREEN}설치: $destination${NC}"
}

ensure_gitignore() {
  [ "$MANAGE_GITIGNORE" = "true" ] || return 0
  if [ -f .gitignore ] && grep -Fq '# BEGIN Universal Build Script' .gitignore; then
    return 0
  fi
  [ ! -L .gitignore ] || { echo -e "${RED}.gitignore 심볼릭 링크는 수정하지 않습니다.${NC}" >&2; return 1; }
  {
    printf '\n# BEGIN Universal Build Script\n'
    printf '%s\n' '.ubs/' '.env' '.env.*' '!.env.example' '!.env.*.example'
    printf '%s\n' 'signing/' '*.p12' '*.p8' '*.pem' '*.key' '*.cer' '*.mobileprovision' '*.provisionprofile' '*.entitlements'
    printf '%s\n' '*.jks' '*.keystore' 'key.properties' 'local.properties' 'GoogleService-Info.plist' 'google-services.json'
    printf '# END Universal Build Script\n'
  } >> .gitignore
  echo -e "${GREEN}보호 규칙: .gitignore UBS 블록${NC}"
}

ensure_gitignore

# 모든 어댑터를 설치해야 모노레포 루트에서 서로 다른 프로젝트를 함께 빌드할 수 있다.
install_file "VERSION"
install_file "build.sh"
install_file "install.sh"
install_file "scripts/ubs.py"
install_file "scripts/bootstrap-update.sh"
install_file "scripts/build-rust-helper.sh"
install_file "native/ubs-helper/Cargo.toml"
install_file "native/ubs-helper/Cargo.lock"
install_file "native/ubs-helper/src/main.rs"
install_file "scripts/lib/detect.sh"
install_file "scripts/lib/audit.sh"
install_file "scripts/lib/node-package-manager.sh"
install_file "scripts/lib/update.sh"
install_file "scripts/build-flutter.sh"
install_file "scripts/build-tauri.sh"
install_file "scripts/build-tauri-macos.sh"
install_file "scripts/build-gradle.sh"
install_file "scripts/build-node.sh"
install_file "scripts/FLUTTER_VERSION"
install_file "scripts/TAURI_VERSION"
install_file "skills/universal-build/SKILL.md"
install_file "skills/universal-build/agents/openai.yaml"
install_file "skills/universal-build/references/optimization.md"
install_file "templates/flutter/ExportOptions.plist"

if [ "${UBS_BUILD_RUST_HELPER:-false}" = "true" ]; then
  if command -v cargo >/dev/null 2>&1; then
    bash scripts/build-rust-helper.sh
  else
    echo -e "${YELLOW}Rust helper 요청을 건너뜁니다: cargo를 찾을 수 없습니다.${NC}"
  fi
fi

if [ "$PROJECT_TYPE" = "flutter" ]; then
  if [ ! -f ".env.example" ]; then
    curl -fsSL "$REPO_RAW/.env.example" -o .env.example
    echo -e "${GREEN}생성: .env.example${NC}"
  fi
  if [ ! -f ".env" ] && [ ! -f ".env.prod" ]; then
    cp .env.example .env
    echo -e "${GREEN}생성: .env${NC}"
    echo -e "${YELLOW}주의: dart-define 값은 앱에 포함될 수 있으므로 비밀키를 넣지 마세요.${NC}"
  fi
  if [ -d "ios" ] && [ ! -f "ios/ExportOptions.plist" ]; then
    curl -fsSL "$REPO_RAW/templates/flutter/ExportOptions.plist" -o ios/ExportOptions.plist
    echo -e "${GREEN}생성: ios/ExportOptions.plist${NC}"
  fi
fi

if [ "$PROJECT_TYPE" = "tauri" ]; then
  if [ ! -f ".env.macos.example" ]; then
    curl -fsSL "$REPO_RAW/.env.macos.example" -o .env.macos.example
    echo -e "${GREEN}생성: .env.macos.example${NC}"
  fi
  if [ ! -f ".env.macos" ]; then
    cp .env.macos.example .env.macos
    chmod 600 .env.macos 2>/dev/null || true
    echo -e "${GREEN}생성: .env.macos${NC}"
  fi
  mkdir -p signing
  echo -e "${YELLOW}signing/에 provisioning profile과 entitlements를 추가하세요.${NC}"
fi

echo "------------------------------------------------------------"
echo -e "${GREEN}🎉 설치 완료${NC}"
echo "프로젝트 확인: ./build.sh detect"
echo "자동 빌드:     ./build.sh"
