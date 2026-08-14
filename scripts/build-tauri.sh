#!/usr/bin/env bash

# Cross-platform entry point. The historical adapter contains the shared Tauri
# build flow and applies Apple signing/package steps only when running on macOS.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/build-tauri-macos.sh" "$@"
