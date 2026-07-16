#!/usr/bin/env bash

# Universal Build Script v2 dispatcher
# - 현재 프로젝트 단일 빌드 (기존 동작 호환)
# - 하위 프로젝트 자동 탐색
# - 여러 프로젝트 순차 빌드

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT_LIB="$SCRIPT_DIR/scripts/lib/detect.sh"

COMMAND="build"
if [ $# -gt 0 ]; then
  case "$1" in
    detect|list) COMMAND="detect"; shift ;;
    audit) COMMAND="audit"; shift ;;
    plan) COMMAND="plan"; shift ;;
    update) COMMAND="update"; shift ;;
    build) COMMAND="build"; shift ;;
    help|-h|--help) COMMAND="help"; shift ;;
  esac
fi

if [ "$COMMAND" != "update" ] && [ "$COMMAND" != "help" ] && [ ! -f "$DETECT_LIB" ]; then
  echo "ERROR: 감지 모듈을 찾을 수 없습니다: $DETECT_LIB" >&2
  exit 1
fi

if [ "$COMMAND" != "update" ] && [ "$COMMAND" != "help" ]; then
  # shellcheck source=scripts/lib/detect.sh
  source "$DETECT_LIB"
fi

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
  ./build.sh detect --json [경로]    AI/MCP용 감지 결과 JSON
  ./build.sh audit [경로]            최적화·난독화 설정 감사
  ./build.sh audit --json [경로]     AI/MCP용 감사 결과 JSON
  ./build.sh plan [경로]             읽기 전용 빌드 계획
  ./build.sh plan --json [경로]      AI/MCP용 빌드 계획 JSON
  ./build.sh update --check          전체 런타임 업데이트 확인
  ./build.sh update --dry-run        변경 파일 미리 보기
  ./build.sh update                  검증·백업 후 안전 업데이트
  ./build.sh --dry-run               실행할 빌드만 미리 확인
  ./build.sh --interactive           버전과 플랫폼을 직접 선택
  ./build.sh build --project <경로>  지정 프로젝트 빌드
  ./build.sh build --all --type TYPE 특정 타입만 빌드

주요 옵션:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android
  --flutter-outputs auto|appbundle,apk,ipa,web
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
  UBS_FLUTTER_OUTPUTS=appbundle,web
  UBS_UPDATE_BASE_URL=https://example.com/Universal-Build-Script
EOF
}

if [ "$COMMAND" = "help" ]; then
  usage
  exit 0
fi

adapter_for() {
  case "$1" in
    tauri) echo "$SCRIPT_DIR/scripts/build-tauri-macos.sh" ;;
    flutter) echo "$SCRIPT_DIR/scripts/build-flutter.sh" ;;
    android|kotlin-multiplatform|kotlin|gradle) echo "$SCRIPT_DIR/scripts/build-gradle.sh" ;;
    react|next|node) echo "$SCRIPT_DIR/scripts/build-node.sh" ;;
    *) return 1 ;;
  esac
}

projects_for_root() {
  local root="$1"
  local direct_type
  direct_type="$(detect_project_type "$root" 2>/dev/null || true)"
  if [ -n "$direct_type" ]; then
    printf '%s\t%s\n' "$direct_type" "$root"
  else
    scan_projects "$root"
  fi
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
  done < <(projects_for_root "$root")

  if [ "$found" = false ]; then
    echo "감지된 프로젝트가 없습니다." >&2
    return 1
  fi
}

require_python_for_json() {
  command -v python3 >/dev/null 2>&1 || {
    echo "--json 출력에는 python3가 필요합니다." >&2
    exit 1
  }
}

print_projects_json() {
  require_python_for_json
  projects_for_root "$1" | python3 -c '
import json, sys
items = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    project_type, path = line.split("\t", 1)
    items.append({"type": project_type, "path": path})
json.dump(items, sys.stdout, ensure_ascii=False, indent=2)
print()
'
}

audit_projects() {
  local root="$1"
  local type path
  while IFS=$'\t' read -r type path; do
    [ -z "$type" ] && continue
    if [ -n "$TYPE_FILTER" ] && [ "$type" != "$TYPE_FILTER" ]; then
      continue
    fi
    audit_project "$type" "$path"
  done < <(projects_for_root "$root")
}

print_audit() {
  local found=false
  local type path category check status detail
  printf '%-22s %-14s %-22s %-18s %s\n' "TYPE" "CATEGORY" "CHECK" "STATUS" "PATH"
  while IFS=$'\t' read -r type path category check status detail; do
    [ -z "$type" ] && continue
    found=true
    printf '%-22s %-14s %-22s %-18s %s\n' "$type" "$category" "$check" "$status" "$path"
    printf '  %s\n' "$detail"
  done < <(audit_projects "$1")
  [ "$found" = true ] || { echo "감사할 프로젝트가 없습니다." >&2; return 1; }
}

print_audit_json() {
  require_python_for_json
  audit_projects "$1" | python3 -c '
import json, sys
items = []
for line in sys.stdin:
    fields = line.rstrip("\n").split("\t", 5)
    if len(fields) != 6:
        continue
    project_type, path, category, check, status, detail = fields
    items.append({
        "type": project_type,
        "path": path,
        "category": category,
        "check": check,
        "status": status,
        "detail": detail,
    })
json.dump(items, sys.stdout, ensure_ascii=False, indent=2)
print()
'
}

plan_projects() {
  local root="$1"
  local type path adapter relative_adapter
  while IFS=$'\t' read -r type path; do
    [ -z "$type" ] && continue
    if [ -n "$TYPE_FILTER" ] && [ "$type" != "$TYPE_FILTER" ]; then
      continue
    fi
    adapter="$(adapter_for "$type")" || continue
    relative_adapter="${adapter#"$SCRIPT_DIR"/}"
    printf '%s\t%s\t%s\n' "$type" "$path" "$relative_adapter"
  done < <(projects_for_root "$root")
}

print_plan() {
  local found=false
  local type path adapter
  while IFS=$'\t' read -r type path adapter; do
    [ -z "$type" ] && continue
    found=true
    run_project "$type" "$path" true
  done < <(plan_projects "$1")
  [ "$found" = true ] || { echo "계획할 프로젝트가 없습니다." >&2; return 1; }
}

print_plan_json() {
  require_python_for_json
  plan_projects "$1" | \
  UBS_PLAN_VERSION_BUMP="$VERSION_BUMP" \
  UBS_PLAN_FLUTTER_PLATFORM="$FLUTTER_PLATFORM" \
  UBS_PLAN_FLUTTER_OUTPUTS="$FLUTTER_OUTPUTS" \
  UBS_PLAN_SKIP_CLEAN="$SKIP_CLEAN" \
  UBS_PLAN_GRADLE_TASK="${UBS_GRADLE_TASK:-}" \
  UBS_PLAN_NODE_BUILD_SCRIPT="${UBS_NODE_BUILD_SCRIPT:-build}" \
  UBS_PLAN_TAURI_PACKAGE_MODE="${UBS_TAURI_PACKAGE_MODE:-auto}" \
  UBS_PLAN_SKIP_INSTALL="${UBS_SKIP_INSTALL:-false}" \
  UBS_PLAN_TAURI_OBFUSCATE_JS="${TAURI_OBFUSCATE_JS:-false}" \
  python3 -c '
import json, os, sys

items = []
for line in sys.stdin:
    fields = line.rstrip("\n").split("\t", 2)
    if len(fields) != 3:
        continue
    project_type, path, adapter = fields
    options = {
        "version_bump": os.environ["UBS_PLAN_VERSION_BUMP"],
    }
    if project_type == "flutter":
        outputs = os.environ["UBS_PLAN_FLUTTER_OUTPUTS"]
        options.update({
            "outputs": outputs,
            "output_selection": "auto-platform" if outputs == "auto" else "explicit",
            "platform": os.environ["UBS_PLAN_FLUTTER_PLATFORM"] if outputs == "auto" else None,
            "skip_clean": os.environ["UBS_PLAN_SKIP_CLEAN"] == "true",
        })
    elif project_type == "tauri":
        options["package_mode"] = os.environ["UBS_PLAN_TAURI_PACKAGE_MODE"]
        options["skip_install"] = os.environ["UBS_PLAN_SKIP_INSTALL"] == "true"
        options["obfuscate_js"] = os.environ["UBS_PLAN_TAURI_OBFUSCATE_JS"] == "true"
    elif project_type in {"android", "kotlin-multiplatform", "kotlin", "gradle"}:
        options["gradle_task"] = os.environ["UBS_PLAN_GRADLE_TASK"] or "auto"
    elif project_type in {"react", "next", "node"}:
        options["build_script"] = os.environ["UBS_PLAN_NODE_BUILD_SCRIPT"]
        options["skip_install"] = os.environ["UBS_PLAN_SKIP_INSTALL"] == "true"
    items.append({
        "type": project_type,
        "path": path,
        "adapter": adapter,
        "options": options,
    })

json.dump(items, sys.stdout, ensure_ascii=False, indent=2)
print()
'
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
    if [ "$type" = "flutter" ]; then
      echo "  Flutter outputs=$FLUTTER_OUTPUTS platform=$FLUTTER_PLATFORM version-bump=$VERSION_BUMP"
    fi
    return 0
  fi

  (
    cd "$project_dir"
    UBS_PROJECT_TYPE="$type" \
    UBS_NON_INTERACTIVE="$NON_INTERACTIVE" \
    UBS_VERSION_BUMP="$VERSION_BUMP" \
    UBS_FLUTTER_PLATFORM="$FLUTTER_PLATFORM" \
    UBS_FLUTTER_OUTPUTS="$FLUTTER_OUTPUTS" \
    UBS_SKIP_CLEAN="$SKIP_CLEAN" \
    bash "$adapter"
  )
}

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
JSON_OUTPUT=false
FLUTTER_OUTPUTS="${UBS_FLUTTER_OUTPUTS:-auto}"
UPDATE_CHECK=false

while [ $# -gt 0 ]; do
  if [ "$COMMAND" = "update" ]; then
    case "$1" in
      --check) UPDATE_CHECK=true ;;
      --dry-run) DRY_RUN=true ;;
      -h|--help) usage; exit 0 ;;
      *) echo "update에서 지원하지 않는 옵션 또는 인자입니다: $1" >&2; exit 2 ;;
    esac
    shift
    continue
  fi
  case "$1" in
    --all) BUILD_ALL=true ;;
    --dry-run) DRY_RUN=true ;;
    --json) JSON_OUTPUT=true ;;
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
    --flutter-outputs)
      [ $# -ge 2 ] || { echo "--flutter-outputs 값이 필요합니다." >&2; exit 2; }
      FLUTTER_OUTPUTS="$2"
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

if [ "$COMMAND" = "update" ]; then
  UPDATE_LIB="$SCRIPT_DIR/scripts/lib/update.sh"
  [ -f "$UPDATE_LIB" ] || { echo "업데이트 모듈을 찾을 수 없습니다: $UPDATE_LIB" >&2; exit 1; }
  # shellcheck source=scripts/lib/update.sh
  source "$UPDATE_LIB"
  ubs_run_update "$SCRIPT_DIR" "$UPDATE_CHECK" "$DRY_RUN"
  exit $?
fi

ROOT="$(canonical_dir "$ROOT")" || {
  echo "경로를 열 수 없습니다: $ROOT" >&2
  exit 1
}

case "$VERSION_BUMP" in none|build|patch|minor|major) ;; *) echo "잘못된 version bump: $VERSION_BUMP" >&2; exit 2 ;; esac
case "$FLUTTER_PLATFORM" in auto|all|ios|android) ;; *) echo "잘못된 Flutter 플랫폼: $FLUTTER_PLATFORM" >&2; exit 2 ;; esac
if [ "$FLUTTER_OUTPUTS" != "auto" ] && ! echo ",$FLUTTER_OUTPUTS," | grep -Eqs '^,(appbundle|apk|ipa|web)(,(appbundle|apk|ipa|web))*,$'; then
  echo "잘못된 Flutter 출력: $FLUTTER_OUTPUTS" >&2
  exit 2
fi

if [ "$COMMAND" = "detect" ]; then
  if [ "$JSON_OUTPUT" = true ]; then print_projects_json "$ROOT"
  else print_projects "$ROOT"
  fi
  exit $?
fi

if [ "$COMMAND" = "audit" ]; then
  AUDIT_LIB="$SCRIPT_DIR/scripts/lib/audit.sh"
  [ -f "$AUDIT_LIB" ] || { echo "감사 모듈을 찾을 수 없습니다: $AUDIT_LIB" >&2; exit 1; }
  # shellcheck source=scripts/lib/audit.sh
  source "$AUDIT_LIB"
  if [ "$JSON_OUTPUT" = true ]; then print_audit_json "$ROOT"
  else print_audit "$ROOT"
  fi
  exit $?
fi

if [ "$COMMAND" = "plan" ]; then
  PLAN_ROOT="$ROOT"
  if [ -n "$PROJECT_PATH" ]; then
    PLAN_ROOT="$(canonical_dir "$PROJECT_PATH")" || {
      echo "프로젝트 경로를 열 수 없습니다: $PROJECT_PATH" >&2
      exit 1
    }
  fi
  if [ "$JSON_OUTPUT" = true ]; then print_plan_json "$PLAN_ROOT"
  else print_plan "$PLAN_ROOT"
  fi
  exit $?
fi

if [ "$JSON_OUTPUT" = true ]; then
  echo "--json은 detect, audit 또는 plan 명령에서 지원합니다." >&2
  exit 2
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
