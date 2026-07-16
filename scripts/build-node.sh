#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

[ -f package.json ] || {
  echo -e "${RED}package.json을 찾을 수 없습니다.${NC}" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/node-package-manager.sh
source "$SCRIPT_DIR/lib/node-package-manager.sh"

BUILD_SCRIPT="${UBS_NODE_BUILD_SCRIPT:-build}"
detect_node_package_manager

START_TS=$(date +%s)
echo -e "${CYAN}Node 프로젝트 빌드 ($NODE_PM, script=$BUILD_SCRIPT)${NC}"
if [ "${UBS_SKIP_INSTALL:-false}" != "true" ]; then
  install_node_dependencies
fi
run_node_script "$BUILD_SCRIPT"
ELAPSED=$(($(date +%s) - START_TS))
echo -e "${GREEN}Node 빌드 완료 (${ELAPSED}s)${NC}"
