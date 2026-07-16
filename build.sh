#!/bin/bash

# =================================================================
# Universal Build Script — Dispatcher
# Description: 프로젝트 루트에서 실행하면 프로젝트 타입(Flutter/Tauri)을
#              자동 감지해서 알맞은 빌드 스크립트로 넘겨준다.
# =================================================================

set -e

CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "pubspec.yaml" ]; then
  echo -e "${CYAN}🎯 Flutter 프로젝트 감지됨 (pubspec.yaml)${NC}"
  exec bash "$SCRIPT_DIR/scripts/build-flutter.sh" "$@"
elif [ -f "src-tauri/tauri.conf.json" ]; then
  echo -e "${CYAN}🎯 Tauri 프로젝트 감지됨 (src-tauri/tauri.conf.json)${NC}"
  exec bash "$SCRIPT_DIR/scripts/build-tauri-macos.sh" "$@"
else
  echo -e "${RED}❌ 프로젝트 타입을 감지할 수 없습니다.${NC}"
  echo -e "   pubspec.yaml (Flutter) 또는 src-tauri/tauri.conf.json (Tauri) 이 있는 디렉토리에서 실행하세요."
  exit 1
fi
