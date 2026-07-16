#!/usr/bin/env bash

# Universal Build Script v2 dispatcher
# - 현재 프로젝트 단일 빌드 (기존 동작 호환)
# - 하위 프로젝트 자동 탐색
# - 여러 프로젝트 순차 빌드

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT_LIB="$SCRIPT_DIR/scripts/lib/detect.sh"

if [ ! -f "$DETECT_LIB" ]; then
  echo "ERROR: 감지 모듈을 찾을 수 없습니다: $DETECT_LIB" >&2
  exit 1
fi

# shellcheck source=scripts/lib/detect.sh
source "$DETECT_LIB"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
  cat <<'EOF'
Universal Build Script

사용법:
  ./build.sh                         자동 감지 + 안전한 기본값으로 무인 빌드
  ./build.sh detect [경로]           하위 프로젝트 탐색
  ./build.sh --dry-run               실행할 빌드만 미리 확인
  ./build.sh --interactive           버전과 플랫폼을 직접 선택
  ./build.sh build --project <경로>  지정 프로젝트 빌드
  ./build.sh build --all --type TYPE 특정 타입만 빌드

주요 옵션:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android
  --clean | --skip-clean
  --fail-fast

지원 타입:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node

환경변수로 기본 빌드 명령을 덮어쓸 수 있습니다:
  UBS_GRADLE_TASK=assembleRelease
  UBS_NODE_BUILD_SCRIPT=build:production
  UBS_SKIP_INSTALL=true
  UBS_SKIP_CLEAN=true
EOF
}

adapter_for() {
  case "$1" in
    tauri) echo "$SCRIPT_DIR/scripts/build-tauri-macos.sh" ;;
    flutter) echo "$SCRIPT_DIR/scripts/build-flutter.sh" ;;
    android|kotlin-multiplatform|kotlin|gradle) echo "$SCRIPT_DIR/scripts/build-gradle.sh" ;;
    react|next|node) echo "$SCRIPT_DIR/scripts/build-node.sh" ;;
    *) return 1 ;;
  esac
}

print_projects() {
  local root="$1"
  local found=false

  printf '%-24s  %s\n' "TYPE" "PATH"
  printf '%-24s  %s\n' "------------------------" "----"
  while IFS=$'\t' read -r type path; do
    [ -z "$type" ] && continue
    found=true
    printf '%-24s  %s\n' "$type" "$path"
  done < <(scan_projects "$root")

  if [ "$found" = false ]; then
    echo "감지된 프로젝트가 없습니다." >&2
    return 1
  fi
}

run_project() {
  local type="$1"
  local project_dir="$2"
  local dry_run="$3"
  local adapter

  adapter="$(adapter_for "$type")" || {
    echo -e "${RED}지원하지 않는 프로젝트 타입입니다: $type${NC}" >&2
    return 1
  }
  if [ ! -f "$adapter" ]; then
    echo -e "${RED}빌드 어댑터가 없습니다: $adapter${NC}" >&2
    return 1
  fi

  echo -e "${CYAN}▶ [$type] $project_dir${NC}"
  if [ "$dry_run" = true ]; then
    echo "  (dry-run) bash $adapter"
    return 0
  fi

  (
    cd "$project_dir"
    UBS_PROJECT_TYPE="$type" \
    UBS_NON_INTERACTIVE="$NON_INTERACTIVE" \
    UBS_VERSION_BUMP="$VERSION_BUMP" \
    UBS_FLUTTER_PLATFORM="$FLUTTER_PLATFORM" \
    UBS_SKIP_CLEAN="$SKIP_CLEAN" \
    bash "$adapter"
  )
}

COMMAND="build"
if [ $# -gt 0 ]; then
  case "$1" in
    detect|list) COMMAND="detect"; shift ;;
    build) COMMAND="build"; shift ;;
    help|-h|--help) usage; exit 0 ;;
  esac
fi

ROOT="$PWD"
BUILD_ALL=false
DRY_RUN=false
TYPE_FILTER=""
PROJECT_PATH=""
NON_INTERACTIVE="${UBS_NON_INTERACTIVE:-true}"
VERSION_BUMP="${UBS_VERSION_BUMP:-none}"
FLUTTER_PLATFORM="${UBS_FLUTTER_PLATFORM:-auto}"
SKIP_CLEAN="${UBS_SKIP_CLEAN:-true}"
FAIL_FAST=false

while [ $# -gt 0 ]; do
  case "$1" in
    --all) BUILD_ALL=true ;;
    --dry-run) DRY_RUN=true ;;
    --non-interactive) NON_INTERACTIVE=true ;;
    --interactive) NON_INTERACTIVE=false ;;
    --skip-clean) SKIP_CLEAN=true ;;
    --clean) SKIP_CLEAN=false ;;
    --fail-fast) FAIL_FAST=true ;;
    --version-bump)
      [ $# -ge 2 ] || { echo "--version-bump 값이 필요합니다." >&2; exit 2; }
      VERSION_BUMP="$2"
      shift
      ;;
    --flutter-platform)
      [ $# -ge 2 ] || { echo "--flutter-platform 값이 필요합니다." >&2; exit 2; }
      FLUTTER_PLATFORM="$2"
      shift
      ;;
    --type)
      [ $# -ge 2 ] || { echo "--type 값이 필요합니다." >&2; exit 2; }
      TYPE_FILTER="$2"
      shift
      ;;
    --project)
      [ $# -ge 2 ] || { echo "--project 경로가 필요합니다." >&2; exit 2; }
      PROJECT_PATH="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "알 수 없는 옵션: $1" >&2; usage; exit 2 ;;
    *) ROOT="$1" ;;
  esac
  shift
done

ROOT="$(canonical_dir "$ROOT")" || {
  echo "경로를 열 수 없습니다: $ROOT" >&2
  exit 1
}

case "$VERSION_BUMP" in none|build|patch|minor|major) ;; *) echo "잘못된 version bump: $VERSION_BUMP" >&2; exit 2 ;; esac
case "$FLUTTER_PLATFORM" in auto|all|ios|android) ;; *) echo "잘못된 Flutter 플랫폼: $FLUTTER_PLATFORM" >&2; exit 2 ;; esac

if [ "$COMMAND" = "detect" ]; then
  print_projects "$ROOT"
  exit $?
fi

if [ -n "$PROJECT_PATH" ]; then
  PROJECT_PATH="$(canonical_dir "$PROJECT_PATH")" || {
    echo "프로젝트 경로를 열 수 없습니다: $PROJECT_PATH" >&2
    exit 1
  }
  PROJECT_TYPE="$(detect_project_type "$PROJECT_PATH" 2>/dev/null || true)"
  [ -n "$PROJECT_TYPE" ] || {
    echo -e "${RED}프로젝트 타입을 감지할 수 없습니다: $PROJECT_PATH${NC}" >&2
    exit 1
  }
  run_project "$PROJECT_TYPE" "$PROJECT_PATH" "$DRY_RUN"
  exit $?
fi

if [ "$BUILD_ALL" = false ]; then
  PROJECT_TYPE="$(detect_project_type "$ROOT" 2>/dev/null || true)"
  if [ -n "$PROJECT_TYPE" ]; then
    run_project "$PROJECT_TYPE" "$ROOT" "$DRY_RUN"
    exit $?
  fi
  echo -e "${CYAN}현재 폴더는 모노레포 루트로 판단했습니다. 하위 프로젝트를 자동 빌드합니다.${NC}"
  BUILD_ALL=true
fi

TOTAL=0
SUCCEEDED=0
FAILED=0

while IFS=$'\t' read -r type project_dir; do
  [ -z "$type" ] && continue
  if [ -n "$TYPE_FILTER" ] && [ "$type" != "$TYPE_FILTER" ]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  if run_project "$type" "$project_dir" "$DRY_RUN"; then
    SUCCEEDED=$((SUCCEEDED + 1))
  else
    FAILED=$((FAILED + 1))
    echo -e "${RED}✗ 빌드 실패: [$type] $project_dir${NC}" >&2
    if [ "$FAIL_FAST" = true ]; then
      break
    fi
  fi
done < <(scan_projects "$ROOT")

if [ "$TOTAL" -eq 0 ]; then
  echo -e "${YELLOW}조건에 맞는 프로젝트가 없습니다.${NC}" >&2
  exit 1
fi

echo "------------------------------------------------------------"
echo -e "전체: $TOTAL  ${GREEN}성공: $SUCCEEDED${NC}  ${RED}실패: $FAILED${NC}"
[ "$FAILED" -eq 0 ]
