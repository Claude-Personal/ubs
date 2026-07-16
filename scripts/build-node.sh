#!/usr/bin/env bash

# Legacy compatibility wrapper. Node execution and dependency caching live in
# the Python core so direct adapter callers share the same implementation.
set -e

RUNTIME_ROOT="${UBS_RUNTIME_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -f "$RUNTIME_ROOT/scripts/ubs.py" ] || {
  echo "Python core를 찾을 수 없습니다: $RUNTIME_ROOT/scripts/ubs.py" >&2
  exit 1
}
exec python3 "$RUNTIME_ROOT/scripts/ubs.py" node-adapter "$PWD"
