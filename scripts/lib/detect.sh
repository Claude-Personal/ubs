#!/usr/bin/env bash

# 프로젝트 타입 감지 전용 모듈. 이 파일은 실행하지 않고 source해서 사용한다.

canonical_dir() {
  (cd "$1" 2>/dev/null && pwd -P)
}

file_contains() {
  local pattern="$1"
  shift
  grep -Eqs "$pattern" "$@" 2>/dev/null
}

has_node_build_script() {
  local package_json="$1/package.json"
  [ -f "$package_json" ] || return 1

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$package_json" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    raise SystemExit(0 if isinstance(data.get("scripts", {}).get("build"), str) else 1)
except Exception:
    raise SystemExit(1)
PY
  else
    grep -Eqs '"build"[[:space:]]*:' "$package_json"
  fi
}

detect_gradle_type() {
  local dir="$1"
  local files_found
  files_found=$(find "$dir" -maxdepth 3 -type f \( -name 'build.gradle' -o -name 'build.gradle.kts' \) -print -quit 2>/dev/null)
  [ -n "$files_found" ] || return 1

  if find "$dir" -maxdepth 3 -type f \( -name 'build.gradle' -o -name 'build.gradle.kts' \) \
    -exec grep -Eqs 'com\.android\.(application|library)' {} + 2>/dev/null; then
    echo "android"
  elif find "$dir" -maxdepth 3 -type f \( -name 'build.gradle' -o -name 'build.gradle.kts' \) \
    -exec grep -Eqs 'multiplatform|org\.jetbrains\.kotlin\.multiplatform' {} + 2>/dev/null; then
    echo "kotlin-multiplatform"
  elif find "$dir" -maxdepth 3 -type f \( -name 'build.gradle' -o -name 'build.gradle.kts' \) \
    -exec grep -Eqs 'org\.jetbrains\.kotlin|kotlin.*(jvm|android)' {} + 2>/dev/null; then
    echo "kotlin"
  else
    echo "gradle"
  fi
}

detect_project_type() {
  local dir="$1"
  local package_json="$dir/package.json"

  # 상위 생태계를 먼저 판별해야 Tauri가 React로, Flutter가 Android로
  # 중복 감지되지 않는다.
  if [ -f "$dir/src-tauri/tauri.conf.json" ]; then
    echo "tauri"
    return 0
  fi

  if [ -f "$dir/pubspec.yaml" ] && \
     file_contains 'sdk:[[:space:]]*flutter|^[[:space:]]*flutter:' "$dir/pubspec.yaml"; then
    echo "flutter"
    return 0
  fi

  if [ -f "$dir/gradlew" ] || [ -f "$dir/settings.gradle" ] || \
     [ -f "$dir/settings.gradle.kts" ] || [ -f "$dir/build.gradle" ] || \
     [ -f "$dir/build.gradle.kts" ]; then
    detect_gradle_type "$dir"
    return 0
  fi

  if [ -f "$package_json" ] && has_node_build_script "$dir"; then
    if file_contains '"next"[[:space:]]*:' "$package_json"; then
      echo "next"
    elif file_contains '"react"[[:space:]]*:' "$package_json"; then
      echo "react"
    else
      echo "node"
    fi
    return 0
  fi

  return 1
}

is_flutter_managed_child() {
  local candidate="$1"
  local root="$2"
  local parent="$candidate"
  local base

  while [ "$parent" != "$root" ] && [ "$parent" != "/" ]; do
    base="$(basename "$parent")"
    parent="$(dirname "$parent")"
    case "$base" in
      android|ios|macos|linux|windows|web)
        if [ "$(detect_project_type "$parent" 2>/dev/null || true)" = "flutter" ]; then
          return 0
        fi
        ;;
    esac
  done
  return 1
}

scan_projects() {
  local root
  local marker
  local candidate
  local type

  root="$(canonical_dir "$1")" || return 1

  find "$root" \
    \( -type d \( -name .git -o -name node_modules -o -name build -o -name dist \
      -o -name target -o -name .gradle -o -name .dart_tool -o -name .next \) -prune \) \
    -o \( -type f \( -name pubspec.yaml -o -name tauri.conf.json \
      -o -name settings.gradle -o -name settings.gradle.kts -o -name package.json \) -print \) \
    2>/dev/null |
  while IFS= read -r marker; do
    case "$marker" in
      */src-tauri/tauri.conf.json)
        candidate="$(dirname "$(dirname "$marker")")"
        ;;
      *) candidate="$(dirname "$marker")" ;;
    esac
    canonical_dir "$candidate"
  done |
  sort -u |
  while IFS= read -r candidate; do
    [ -z "$candidate" ] && continue
    if is_flutter_managed_child "$candidate" "$root"; then
      continue
    fi
    type="$(detect_project_type "$candidate" 2>/dev/null || true)"
    [ -n "$type" ] && printf '%s\t%s\n' "$type" "$candidate"
  done
}
