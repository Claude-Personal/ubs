#!/usr/bin/env bash

# packageManager 필드와 lock 파일을 이용해 Node 패키지 매니저를 통일해서 선택한다.

detect_node_package_manager() {
  local declared=""
  local current="$PWD"

  NODE_WORKSPACE_ROOT="$PWD"
  while [ "$current" != "/" ]; do
    if [ "$current" != "$PWD" ] && {
      [ -f "$current/pnpm-lock.yaml" ] || [ -f "$current/yarn.lock" ] || \
      [ -f "$current/package-lock.json" ] || [ -f "$current/npm-shrinkwrap.json" ] || \
      [ -f "$current/bun.lock" ] || [ -f "$current/bun.lockb" ] || \
      [ -f "$current/pnpm-workspace.yaml" ] || \
      { [ -f "$current/package.json" ] && grep -Eqs '"(packageManager|workspaces)"[[:space:]]*:' "$current/package.json"; };
    }; then
      NODE_WORKSPACE_ROOT="$current"
      break
    fi
    [ -e "$current/.git" ] && break
    current="$(dirname "$current")"
  done

  if command -v python3 >/dev/null 2>&1 && [ -f "$NODE_WORKSPACE_ROOT/package.json" ]; then
    declared=$(python3 - "$NODE_WORKSPACE_ROOT/package.json" <<'PY'
import json, sys
try:
    value = json.load(open(sys.argv[1], encoding="utf-8")).get("packageManager", "")
    print(value.split("@", 1)[0] if isinstance(value, str) else "")
except Exception:
    print("")
PY
    )
  fi

  case "$declared" in
    npm|pnpm|yarn|bun) NODE_PM="$declared" ;;
    *)
      if [ -f "$NODE_WORKSPACE_ROOT/pnpm-lock.yaml" ]; then NODE_PM="pnpm"
      elif [ -f "$NODE_WORKSPACE_ROOT/yarn.lock" ]; then NODE_PM="yarn"
      elif [ -f "$NODE_WORKSPACE_ROOT/bun.lockb" ] || [ -f "$NODE_WORKSPACE_ROOT/bun.lock" ]; then NODE_PM="bun"
      else NODE_PM="npm"
      fi
      ;;
  esac

  command -v "$NODE_PM" >/dev/null 2>&1 || {
    echo "$NODE_PM 패키지 매니저가 필요합니다." >&2
    return 1
  }
}

node_dependency_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  else shasum -a 256 | awk '{print $1}'
  fi
}

node_dependency_digest() {
  command -v node >/dev/null 2>&1 && node --version
  command -v "$NODE_PM" >/dev/null 2>&1 && "$NODE_PM" --version
  local file
  for file in package.json package-lock.json pnpm-lock.yaml yarn.lock npm-shrinkwrap.json bun.lock bun.lockb .yarnrc.yml; do
    [ -f "$file" ] && { printf '%s\n' "$file"; cat "$file"; }
  done
}

install_node_dependencies() {
  (
  cd "$NODE_WORKSPACE_ROOT"
  local stamp="node_modules/.ubs-install-sha256"
  local digest=""
  if [ "${UBS_INSTALL_MODE:-auto}" = "auto" ]; then
    digest="$(node_dependency_digest | node_dependency_sha256)"
    if [ -f "$stamp" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$digest" ]; then
      echo -e "${CYAN}ℹ️  의존성 입력이 변경되지 않아 $NODE_PM install을 생략합니다.${NC}"
      return 0
    fi
  fi
  case "$NODE_PM" in
    pnpm)
      if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile
      else pnpm install
      fi
      ;;
    yarn)
      if [ -f .yarnrc.yml ]; then yarn install --immutable
      elif [ -f yarn.lock ]; then yarn install --frozen-lockfile
      else yarn install
      fi
      ;;
    bun)
      if [ -f bun.lockb ] || [ -f bun.lock ]; then bun install --frozen-lockfile
      else bun install
      fi
      ;;
    npm)
      if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
        npm ci --no-fund --no-audit
      else
        npm install --no-fund --no-audit
      fi
      ;;
  esac
  local status=$?
  if [ $status -eq 0 ] && [ -d node_modules ]; then
    node_dependency_digest | node_dependency_sha256 > "$stamp"
  fi
  return $status
  )
}

run_node_script() {
  local script="$1"
  shift
  "$NODE_PM" run "$script" "$@"
}
