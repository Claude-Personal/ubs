#!/usr/bin/env bash

# Stable compatibility entry point. Structured orchestration lives in Python;
# ecosystem-specific build commands remain in the Bash adapters.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$SCRIPT_DIR/scripts/ubs.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Universal Build Script에는 Python 3가 필요합니다." >&2
  exit 1
fi
if [ ! -f "$CORE" ] && [ "${1:-}" = "update" ] && [ -f "$SCRIPT_DIR/scripts/bootstrap-update.sh" ]; then
  shift
  exec bash "$SCRIPT_DIR/scripts/bootstrap-update.sh" "$@"
fi
if [ ! -f "$CORE" ]; then
  echo "ERROR: Python 코어를 찾을 수 없습니다: $CORE" >&2
  echo "설치기를 다시 실행하여 관리 런타임을 복구하세요." >&2
  exit 1
fi

exec python3 "$CORE" "$@"
