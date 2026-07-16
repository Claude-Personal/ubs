#!/usr/bin/env bash

# Minimal recovery path used only when scripts/ubs.py is missing. Normal update
# orchestration is performed by the Python core.
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE_LIB="$ROOT/scripts/lib/update.sh"
CHECK=false
DRY_RUN=false
JSON=false
PRUNE_DAYS=""

[ -f "$UPDATE_LIB" ] || { echo "업데이트 모듈을 찾을 수 없습니다: $UPDATE_LIB" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=true ;;
    --dry-run) DRY_RUN=true ;;
    --json) JSON=true ;;
    --prune-backups)
      [ $# -ge 2 ] || { echo "--prune-backups 일수가 필요합니다." >&2; exit 2; }
      PRUNE_DAYS="$2"
      shift
      ;;
    *) echo "update에서 지원하지 않는 옵션 또는 인자입니다: $1" >&2; exit 2 ;;
  esac
  shift
done

# shellcheck source=scripts/lib/update.sh
source "$UPDATE_LIB"

HELPER_SUFFIX=""
[ "${OS:-}" = "Windows_NT" ] && HELPER_SUFFIX=".exe"
if [ -z "${UBS_RUST_HELPER:-}" ] && [ -x "$ROOT/.ubs/bin/ubs-helper$HELPER_SUFFIX" ]; then
  UBS_RUST_HELPER="$ROOT/.ubs/bin/ubs-helper$HELPER_SUFFIX"
  export UBS_RUST_HELPER
fi

if [ -n "$PRUNE_DAYS" ]; then
  [ "$CHECK" = false ] && [ "$DRY_RUN" = false ] || {
    echo "--prune-backups는 --check/--dry-run과 함께 사용할 수 없습니다." >&2
    exit 2
  }
  ubs_update_prune_backups "$ROOT" "$PRUNE_DAYS" "$JSON"
  exit $?
fi

if [ "$JSON" = true ]; then
  set +e
  OUTPUT="$(ubs_run_update "$ROOT" "$CHECK" "$DRY_RUN")"
  STATUS=$?
  set -e
  MODE="$([ "$CHECK" = true ] && echo check || { [ "$DRY_RUN" = true ] && echo dry-run || echo apply; })"
  UBS_UPDATE_JSON_STATUS="$STATUS" UBS_UPDATE_JSON_MODE="$MODE" \
    python3 -c '
import json, os, re, sys
lines = sys.stdin.read().splitlines()
local = remote = backup = None
changed = []
for line in lines:
    match = re.match(r"Universal Build Script: local=(\S+) remote=(\S+)", line)
    if match: local, remote = match.groups()
    elif line.startswith("  - "): changed.append(line[4:])
    elif line.startswith("백업 위치: "): backup = line.removeprefix("백업 위치: ")
print(json.dumps({"schema_version": 1, "ok": os.environ["UBS_UPDATE_JSON_STATUS"] == "0", "status": int(os.environ["UBS_UPDATE_JSON_STATUS"]), "mode": os.environ["UBS_UPDATE_JSON_MODE"], "local_version": local, "remote_version": remote, "changed_paths": changed, "backup_path": backup, "output": lines}, ensure_ascii=False, indent=2))
' <<< "$OUTPUT"
  exit "$STATUS"
fi

ubs_run_update "$ROOT" "$CHECK" "$DRY_RUN"
