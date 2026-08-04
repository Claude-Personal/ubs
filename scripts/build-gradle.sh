#!/usr/bin/env bash

# Legacy compatibility wrapper. Gradle task selection and execution live in
# the Python core so direct adapter callers share the same implementation.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/i18n.sh"
RUNTIME_ROOT="${UBS_RUNTIME_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
[ -f "$RUNTIME_ROOT/scripts/ubs.py" ] || {
  echo "$(ubs_msg ADAPTER_CORE_NOT_FOUND "$RUNTIME_ROOT/scripts/ubs.py")" >&2
  exit 1
}
exec python3 "$RUNTIME_ROOT/scripts/ubs.py" gradle-adapter "$PWD"
