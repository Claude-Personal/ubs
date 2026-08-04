#!/usr/bin/env bash

# Stable compatibility entry point. Structured orchestration lives in Python;
# ecosystem-specific build commands remain in the Bash adapters.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$SCRIPT_DIR/scripts/ubs.py"
I18N_LIB="$SCRIPT_DIR/scripts/lib/i18n.sh"
if [ -f "$I18N_LIB" ]; then
  source "$I18N_LIB"
else
  # i18n.sh is itself a managed file the self-heal path below can restore —
  # don't let its absence crash before that path gets a chance to run.
  ubs_msg() { printf '%s' "$1"; }
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "$(ubs_msg BUILD_NEED_PYTHON3)" >&2
  exit 1
fi
if { [ ! -f "$CORE" ] || [ ! -f "$I18N_LIB" ]; } && [ "${1:-}" = "update" ] && [ -f "$SCRIPT_DIR/scripts/bootstrap-update.sh" ]; then
  shift
  exec bash "$SCRIPT_DIR/scripts/bootstrap-update.sh" "$@"
fi
if [ ! -f "$CORE" ]; then
  echo "$(ubs_msg BUILD_CORE_NOT_FOUND "$CORE")" >&2
  echo "$(ubs_msg BUILD_REINSTALL_HINT)" >&2
  exit 1
fi

exec python3 "$CORE" "$@"
