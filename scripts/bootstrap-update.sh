#!/usr/bin/env bash

# Minimal recovery path used only when scripts/ubs.py is missing. Normal update
# orchestration is performed by the Python core.
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE_LIB="$ROOT/scripts/lib/update.sh"
I18N_LIB="$ROOT/scripts/lib/i18n.sh"
if [ -f "$I18N_LIB" ]; then
  source "$I18N_LIB"
else
  # This script IS the self-heal path — if i18n.sh is what's missing, we still
  # need to be able to print the "can't recover" message below without it.
  ubs_msg() { printf '%s' "$1"; }
fi
CHECK=false
DRY_RUN=false
JSON=false
PRUNE_DAYS=""

[ -f "$UPDATE_LIB" ] || { echo "$(ubs_msg BOOTSTRAP_UPDATE_LIB_NOT_FOUND "$UPDATE_LIB")" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=true ;;
    --dry-run) DRY_RUN=true ;;
    --json) JSON=true ;;
    --prune-backups)
      [ $# -ge 2 ] || { echo "$(ubs_msg BOOTSTRAP_PRUNE_DAYS_REQUIRED)" >&2; exit 2; }
      PRUNE_DAYS="$2"
      shift
      ;;
    *) echo "$(ubs_msg BOOTSTRAP_UPDATE_UNSUPPORTED_ARG "$1")" >&2; exit 2 ;;
  esac
  shift
done

# shellcheck source=scripts/lib/update.sh
source "$UPDATE_LIB"

HELPER_SUFFIX=""
[ "${OS:-}" = "Windows_NT" ] && HELPER_SUFFIX=".exe"
HELPER_PATH="$ROOT/.ubs/bin/ubs-helper$HELPER_SUFFIX"
HELPER_CHECKSUM="$HELPER_PATH.sha256"
HELPER_VERIFIED=false
if [ -f "$HELPER_PATH" ] && [ -f "$HELPER_CHECKSUM" ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    HELPER_ACTUAL="$(sha256sum "$HELPER_PATH" | awk '{print $1}')"
  else
    HELPER_ACTUAL="$(shasum -a 256 "$HELPER_PATH" | awk '{print $1}')"
  fi
  [ "$HELPER_ACTUAL" = "$(tr -d '[:space:]' < "$HELPER_CHECKSUM")" ] && HELPER_VERIFIED=true
fi
if [ -z "${UBS_RUST_HELPER:-}" ] && \
   [ ! -L "$ROOT/.ubs" ] && [ ! -L "$ROOT/.ubs/bin" ] && \
   [ ! -L "$HELPER_PATH" ] && [ ! -L "$HELPER_CHECKSUM" ] && \
   [ "$HELPER_VERIFIED" = true ] && [ -x "$HELPER_PATH" ]; then
  UBS_RUST_HELPER="$HELPER_PATH"
  export UBS_RUST_HELPER
fi

if [ -n "$PRUNE_DAYS" ]; then
  [ "$CHECK" = false ] && [ "$DRY_RUN" = false ] || {
    echo "$(ubs_msg BOOTSTRAP_PRUNE_NEEDS_CHECK_OR_DRYRUN)" >&2
    exit 2
  }
  ubs_update_prune_backups "$ROOT" "$PRUNE_DAYS" "$JSON"
  exit $?
fi

if [ "$JSON" = true ]; then
  set +e
  # Parsed below by fixed-English prefix match, so force en regardless of the
  # user's UBS_LANG — otherwise a non-en locale silently breaks backup parsing.
  # ubs_run_update is a function in *this* shell, so a `VAR=val` prefix has no
  # effect on it (scripts/lib/i18n.sh resolves UBS_LANG once at source time) —
  # re-exec in a fresh subprocess instead, so the override actually takes hold.
  OUTPUT="$(UBS_LANG=en bash -c 'source "$1"; source "$2"; ubs_run_update "$3" "$4" "$5"' \
    _ "$ROOT/scripts/lib/i18n.sh" "$UPDATE_LIB" "$ROOT" "$CHECK" "$DRY_RUN")"
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
    elif line.startswith("Backup location: "): backup = line.removeprefix("Backup location: ")
print(json.dumps({"schema_version": 1, "ok": os.environ["UBS_UPDATE_JSON_STATUS"] == "0", "status": int(os.environ["UBS_UPDATE_JSON_STATUS"]), "mode": os.environ["UBS_UPDATE_JSON_MODE"], "local_version": local, "remote_version": remote, "changed_paths": changed, "backup_path": backup, "output": lines}, ensure_ascii=False, indent=2))
' <<< "$OUTPUT"
  exit "$STATUS"
fi

ubs_run_update "$ROOT" "$CHECK" "$DRY_RUN"
