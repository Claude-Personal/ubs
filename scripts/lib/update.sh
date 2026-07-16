#!/usr/bin/env bash

# Universal Build Script의 제한된 런타임 번들을 안전하게 갱신한다.
# 원격 manifest는 무결성 확인용이며 별도의 서명 체계를 대체하지 않는다.

UBS_UPDATE_DEFAULT_BASE_URL="https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main"
UBS_UPDATE_RELEASE_ROOT="https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script"

ubs_update_allowed_path() {
  case "$1" in
    VERSION|build.sh|install.sh|scripts/ubs.py|scripts/bootstrap-update.sh|scripts/build-rust-helper.sh|\
    native/ubs-helper/Cargo.toml|native/ubs-helper/Cargo.lock|native/ubs-helper/src/main.rs|\
    scripts/FLUTTER_VERSION|scripts/TAURI_VERSION|\
    scripts/build-flutter.sh|scripts/build-tauri.sh|scripts/build-tauri-macos.sh|scripts/build-gradle.sh|\
    scripts/build-node.sh|scripts/lib/detect.sh|scripts/lib/audit.sh|\
    scripts/lib/node-package-manager.sh|scripts/lib/update.sh|\
    skills/universal-build/SKILL.md|skills/universal-build/agents/openai.yaml|\
    skills/universal-build/references/optimization.md|templates/flutter/ExportOptions.plist) return 0 ;;
    *) return 1 ;;
  esac
}

ubs_update_required_paths() {
  cat <<'EOF'
VERSION
build.sh
install.sh
scripts/ubs.py
scripts/bootstrap-update.sh
scripts/build-rust-helper.sh
native/ubs-helper/Cargo.toml
native/ubs-helper/Cargo.lock
native/ubs-helper/src/main.rs
scripts/FLUTTER_VERSION
scripts/TAURI_VERSION
scripts/build-flutter.sh
scripts/build-tauri.sh
scripts/build-tauri-macos.sh
scripts/build-gradle.sh
scripts/build-node.sh
scripts/lib/detect.sh
scripts/lib/audit.sh
scripts/lib/node-package-manager.sh
scripts/lib/update.sh
skills/universal-build/SKILL.md
skills/universal-build/agents/openai.yaml
skills/universal-build/references/optimization.md
templates/flutter/ExportOptions.plist
EOF
}

ubs_update_prune_backups() {
  local root="$1" days="$2" json="${3:-false}" backups
  local count=0 backup_path
  backups="$root/.ubs/backups"
  printf '%s' "$days" | grep -Eqs '^[0-9]+$' || { echo "보존 일수는 0 이상의 정수여야 합니다: $days" >&2; return 2; }
  if [ -L "$root/.ubs" ] || [ -L "$backups" ]; then
    echo "심볼릭 링크 백업 경로는 정리하지 않습니다: $backups" >&2
    return 1
  fi
  if [ -d "$backups" ]; then
    while IFS= read -r backup_path; do
      [ -n "$backup_path" ] || continue
      rm -rf "$backup_path"
      count=$((count + 1))
    done < <(find "$backups" -mindepth 1 -maxdepth 1 -type d -mtime "+$days" -print)
  fi
  if [ "$json" = true ]; then
    printf '{"ok":true,"mode":"prune-backups","retention_days":%s,"deleted":%s}\n' "$days" "$count"
  else
    echo "백업 정리 완료: ${days}일 초과 디렉터리 ${count}개 삭제"
  fi
}

ubs_update_sha256() {
  if [ -n "${UBS_RUST_HELPER:-}" ] && [ -x "$UBS_RUST_HELPER" ]; then
    "$UBS_RUST_HELPER" sha256 "$1"
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "SHA-256 도구(sha256sum 또는 shasum)가 필요합니다." >&2
    return 1
  fi
}

ubs_update_fetch() {
  local url="$1" output="$2"
  curl -fsSL --retry 2 --connect-timeout 5 --max-time 30 "$url" -o "$output"
}

ubs_update_semver_compare() {
  awk -v left="$1" -v right="$2" 'BEGIN {
    split(left, a, "."); split(right, b, ".")
    for (i = 1; i <= 3; i++) {
      if ((a[i] + 0) > (b[i] + 0)) { print 1; exit }
      if ((a[i] + 0) < (b[i] + 0)) { print -1; exit }
    }
    print 0
  }'
}

ubs_update_cleanup() {
  if [ -n "${UBS_UPDATE_CLEANUP_TEMP:-}" ]; then
    rm -rf "$UBS_UPDATE_CLEANUP_TEMP" || true
  fi
  if [ -n "${UBS_UPDATE_CLEANUP_LOCK:-}" ]; then
    rmdir "$UBS_UPDATE_CLEANUP_LOCK" 2>/dev/null || true
  fi
}

ubs_update_safe_destination() {
  local root="$1" relative="$2" current component old_ifs
  ubs_update_allowed_path "$relative" || return 1
  if [ -n "${UBS_RUST_HELPER:-}" ] && [ -x "$UBS_RUST_HELPER" ]; then
    "$UBS_RUST_HELPER" validate-relative "$relative" || return 1
  fi
  case "$relative" in /*|*../*|../*|*/..) return 1 ;; esac

  current="$root"
  old_ifs="$IFS"
  IFS='/'
  for component in $relative; do
    current="$current/$component"
    if [ -L "$current" ]; then
      IFS="$old_ifs"
      echo "심볼릭 링크 경로는 업데이트하지 않습니다: $relative" >&2
      return 1
    fi
  done
  IFS="$old_ifs"
}

ubs_update_restore() {
  local root="$1" backup="$2"
  shift 2
  local relative destination restore_tmp
  for relative in "$@"; do
    destination="$root/$relative"
    if [ -e "$backup/$relative" ]; then
      mkdir -p "$(dirname "$destination")" || { echo "복원 경로 생성 실패: $relative" >&2; continue; }
      restore_tmp="$(mktemp "$destination.ubs-restore.XXXXXX")" || {
        echo "복원 임시 파일 생성 실패: $relative" >&2
        continue
      }
      if ! cp -p "$backup/$relative" "$restore_tmp" || ! mv -f "$restore_tmp" "$destination"; then
        echo "복원 실패: $relative" >&2
        rm -f "$restore_tmp" || true
      fi
    else
      rm -f "$destination" || echo "새 파일 제거 실패: $relative" >&2
    fi
  done
}

ubs_run_update() {
  local root="$1" check_only="$2" dry_run="$3"
  local base_url payload_base_url manifest_url temp_dir manifest remote_version="" seen=""
  local kind value relative extra expected actual local_version changed_count=0
  local required timestamp backup_dir destination install_tmp mode version_order lock_dir i changed_file helper_dir root_helper_dir
  local rust_batch=false rust_source_changed=false
  local -a paths hashes changed_paths installed_paths

  command -v curl >/dev/null 2>&1 || { echo "업데이트에는 curl이 필요합니다." >&2; return 1; }

  base_url="${UBS_UPDATE_BASE_URL:-$UBS_UPDATE_DEFAULT_BASE_URL}"
  base_url="${base_url%/}"
  case "$base_url" in
    https://*) ;;
    file://*)
      [ "${UBS_UPDATE_ALLOW_FILE:-false}" = "true" ] || {
        echo "file:// 업데이트는 테스트 모드에서만 허용됩니다." >&2
        return 1
      }
      ;;
    *) echo "업데이트 URL은 HTTPS만 허용됩니다: $base_url" >&2; return 1 ;;
  esac

  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ubs-update.XXXXXX")" || return 1
  manifest="$temp_dir/update-manifest.txt"
  manifest_url="$base_url/scripts/update-manifest.txt"
  if ! ubs_update_fetch "$manifest_url" "$manifest"; then
    echo "업데이트 manifest를 가져오지 못했습니다: $manifest_url" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  if [ -n "${UBS_UPDATE_MANIFEST_SHA256:-}" ]; then
    actual="$(ubs_update_sha256 "$manifest")" || { rm -rf "$temp_dir"; return 1; }
    if [ "$actual" != "$UBS_UPDATE_MANIFEST_SHA256" ]; then
      echo "고정한 manifest SHA-256과 일치하지 않습니다." >&2
      rm -rf "$temp_dir"
      return 1
    fi
  fi

  while IFS=' ' read -r kind value relative extra; do
    [ -z "$kind" ] && continue
    case "$kind" in
      \#*) continue ;;
      version)
        if [ -n "$remote_version" ] || [ -z "$value" ] || [ -n "$relative" ]; then
          echo "잘못된 version 항목입니다." >&2
          rm -rf "$temp_dir"
          return 1
        fi
        remote_version="$value"
        ;;
      file)
        if ! printf '%s' "$value" | grep -Eqs '^[0-9a-f]{64}$' || \
           [ -z "$relative" ] || [ -n "$extra" ] || \
           ! ubs_update_allowed_path "$relative"; then
          echo "허용되지 않거나 잘못된 manifest 항목입니다: $relative" >&2
          rm -rf "$temp_dir"
          return 1
        fi
        case " $seen " in
          *" $relative "*)
            echo "중복된 manifest 경로입니다: $relative" >&2
            rm -rf "$temp_dir"
            return 1
            ;;
        esac
        seen="$seen $relative"
        paths+=("$relative")
        hashes+=("$value")
        ;;
      *)
        echo "알 수 없는 manifest 항목입니다: $kind" >&2
        rm -rf "$temp_dir"
        return 1
        ;;
    esac
  done < "$manifest"

  if ! printf '%s' "$remote_version" | grep -Eqs '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "manifest version은 숫자 SemVer 형식이어야 합니다: $remote_version" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  payload_base_url="$base_url"
  if [ "$base_url" = "$UBS_UPDATE_DEFAULT_BASE_URL" ] && \
     [ "${UBS_UPDATE_USE_RELEASE_TAGS:-true}" = true ]; then
    payload_base_url="$UBS_UPDATE_RELEASE_ROOT/v$remote_version"
  fi
  while IFS= read -r required; do
    case " $seen " in
      *" $required "*) ;;
      *) echo "manifest 필수 경로가 누락됐습니다: $required" >&2; rm -rf "$temp_dir"; return 1 ;;
    esac
  done < <(ubs_update_required_paths)

  local_version="unknown"
  [ -f "$root/VERSION" ] && local_version="$(tr -d '[:space:]' < "$root/VERSION")"
  if printf '%s' "$local_version" | grep -Eqs '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    version_order="$(ubs_update_semver_compare "$remote_version" "$local_version")"
    if [ "$version_order" = "-1" ] && [ "${UBS_UPDATE_ALLOW_DOWNGRADE:-false}" != "true" ]; then
      echo "다운그레이드를 차단했습니다: local=$local_version remote=$remote_version" >&2
      echo "복원이 필요하면 .ubs/backups/를 사용하거나 UBS_UPDATE_ALLOW_DOWNGRADE=true를 명시하세요." >&2
      rm -rf "$temp_dir"
      return 1
    fi
  fi

  for ((i = 0; i < ${#paths[@]}; i++)); do
    relative="${paths[$i]}"
    if ! ubs_update_safe_destination "$root" "$relative"; then
      rm -rf "$temp_dir"
      return 1
    fi
  done

  if [ -n "${UBS_RUST_HELPER:-}" ] && [ -x "$UBS_RUST_HELPER" ]; then
    changed_file="$temp_dir/changed-paths.txt"
    if "$UBS_RUST_HELPER" changed-manifest "$manifest" "$root" > "$changed_file" 2>/dev/null; then
      rust_batch=true
      while IFS= read -r relative; do
        [ -n "$relative" ] || continue
        case " ${paths[*]} " in
          *" $relative "*) ;;
          *) echo "Rust helper가 manifest 밖 경로를 반환했습니다: $relative" >&2; rm -rf "$temp_dir"; return 1 ;;
        esac
        case " ${changed_paths[*]} " in
          *" $relative "*) echo "Rust helper가 중복 경로를 반환했습니다: $relative" >&2; rm -rf "$temp_dir"; return 1 ;;
        esac
        changed_paths+=("$relative")
        changed_count=$((changed_count + 1))
      done < "$changed_file"
    else
      echo "Rust helper가 batch manifest 명령을 지원하지 않아 portable hash fallback을 사용합니다." >&2
    fi
  fi

  if [ "$rust_batch" != true ]; then
    for ((i = 0; i < ${#paths[@]}; i++)); do
      relative="${paths[$i]}"
      expected="${hashes[$i]}"
      actual=""
      [ -f "$root/$relative" ] && actual="$(ubs_update_sha256 "$root/$relative")"
      if [ "$actual" != "$expected" ]; then
        changed_paths+=("$relative")
        changed_count=$((changed_count + 1))
      fi
    done
  fi

  echo "Universal Build Script: local=$local_version remote=$remote_version"
  if [ "$changed_count" -eq 0 ]; then
    echo "이미 최신 상태이며 관리 파일의 무결성도 일치합니다."
    rm -rf "$temp_dir"
    return 0
  fi

  echo "변경 대상: ${changed_count}개"
  printf '  - %s\n' "${changed_paths[@]}"
  if [ "$check_only" = true ]; then
    echo "확인만 수행했습니다. 적용하려면: ./build.sh update"
    rm -rf "$temp_dir"
    return 0
  fi
  if [ "$dry_run" = true ]; then
    echo "dry-run이므로 다운로드·백업·교체하지 않았습니다."
    rm -rf "$temp_dir"
    return 0
  fi

  if [ -L "$root/.ubs" ] || [ -L "$root/.ubs/backups" ]; then
    echo "심볼릭 링크 백업 경로는 사용하지 않습니다: $root/.ubs" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  mkdir -p "$root/.ubs" || { echo "업데이트 상태 경로를 만들 수 없습니다." >&2; rm -rf "$temp_dir"; return 1; }
  lock_dir="$root/.ubs/update.lock"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "다른 업데이트가 진행 중입니다: $lock_dir" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  UBS_UPDATE_CLEANUP_TEMP="$temp_dir"
  UBS_UPDATE_CLEANUP_LOCK="$lock_dir"
  trap ubs_update_cleanup EXIT

  for ((i = 0; i < ${#paths[@]}; i++)); do
    relative="${paths[$i]}"
    expected="${hashes[$i]}"
    case " ${changed_paths[*]} " in *" $relative "*) ;; *) continue ;; esac
    if ! mkdir -p "$temp_dir/stage/$(dirname "$relative")"; then
      echo "임시 경로 생성 실패: $relative" >&2
      rm -rf "$temp_dir"
      return 1
    fi
    if ! ubs_update_fetch "$payload_base_url/$relative" "$temp_dir/stage/$relative"; then
      echo "파일 다운로드 실패: $relative" >&2
      rm -rf "$temp_dir"
      return 1
    fi
    if [ "$rust_batch" != true ]; then
      actual="$(ubs_update_sha256 "$temp_dir/stage/$relative")" || { rm -rf "$temp_dir"; return 1; }
      if [ "$actual" != "$expected" ]; then
        echo "SHA-256 불일치: $relative" >&2
        rm -rf "$temp_dir"
        return 1
      fi
    fi
  done
  if [ "$rust_batch" = true ] && \
     ! "$UBS_RUST_HELPER" verify-manifest "$manifest" "$temp_dir/stage" "${changed_paths[@]}"; then
    echo "Rust batch manifest 검증에 실패했습니다." >&2
    rm -rf "$temp_dir"
    return 1
  fi

  timestamp="$(date '+%Y%m%d-%H%M%S')-$$"
  backup_dir="$root/.ubs/backups/$timestamp"
  if ! mkdir -p "$backup_dir"; then
    echo "백업 경로를 만들 수 없습니다: $backup_dir" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  for relative in "${changed_paths[@]}"; do
    if ! ubs_update_safe_destination "$root" "$relative"; then
      echo "백업 직전 경로 검증 실패: $relative" >&2
      rm -rf "$temp_dir"
      return 1
    fi
    if [ -e "$root/$relative" ]; then
      if ! mkdir -p "$backup_dir/$(dirname "$relative")" || \
         ! cp -p "$root/$relative" "$backup_dir/$relative"; then
        echo "백업 실패: $relative" >&2
        rm -rf "$temp_dir"
        return 1
      fi
    fi
  done

  for relative in "${changed_paths[@]}"; do
    if ! ubs_update_safe_destination "$root" "$relative"; then
      echo "교체 직전 경로 검증 실패: $relative — 적용된 파일을 복원합니다." >&2
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -rf "$temp_dir"
      return 1
    fi
    destination="$root/$relative"
    if ! mkdir -p "$(dirname "$destination")"; then
      echo "대상 경로 생성 실패: $relative — 적용된 파일을 복원합니다." >&2
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -rf "$temp_dir"
      return 1
    fi
    install_tmp="$(mktemp "$destination.ubs-new.XXXXXX")" || {
      echo "교체 임시 파일 생성 실패: $relative — 적용된 파일을 복원합니다." >&2
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -rf "$temp_dir"
      return 1
    }
    if ! cp "$temp_dir/stage/$relative" "$install_tmp"; then
      echo "교체 준비 실패: $relative" >&2
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -rf "$temp_dir"
      return 1
    fi
    case "$relative" in *.sh) mode=755 ;; *) mode=644 ;; esac
    if ! chmod "$mode" "$install_tmp"; then
      echo "권한 설정 실패: $relative — 적용된 파일을 복원합니다." >&2
      rm -f "$install_tmp"
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -rf "$temp_dir"
      return 1
    fi
    if ! mv -f "$install_tmp" "$destination"; then
      echo "교체 실패: $relative — 적용된 파일을 복원합니다." >&2
      ubs_update_restore "$root" "$backup_dir" "${installed_paths[@]}"
      rm -f "$install_tmp"
      rm -rf "$temp_dir"
      return 1
    fi
    installed_paths+=("$relative")
    case "$relative" in
      native/ubs-helper/*|scripts/build-rust-helper.sh) rust_source_changed=true ;;
    esac
  done

  helper_dir=""
  root_helper_dir=""
  [ -z "${UBS_RUST_HELPER:-}" ] || helper_dir="$(cd "$(dirname "$UBS_RUST_HELPER")" 2>/dev/null && pwd -P || true)"
  [ ! -d "$root/.ubs/bin" ] || root_helper_dir="$(cd "$root/.ubs/bin" && pwd -P)"
  if [ "$rust_source_changed" = true ] && \
     [ -n "$helper_dir" ] && [ "$helper_dir" = "$root_helper_dir" ]; then
    if command -v cargo >/dev/null 2>&1; then
      if ! bash "$root/scripts/build-rust-helper.sh"; then
        echo "경고: 관리 파일은 갱신됐지만 Rust helper 재빌드에 실패했습니다. portable fallback을 사용할 수 있습니다." >&2
      fi
    else
      echo "경고: Rust helper 소스가 갱신됐지만 cargo가 없어 바이너리를 재빌드하지 못했습니다." >&2
    fi
  fi

  ubs_update_cleanup
  UBS_UPDATE_CLEANUP_TEMP=""
  UBS_UPDATE_CLEANUP_LOCK=""
  trap - EXIT
  echo "업데이트 완료: $remote_version"
  echo "백업 위치: $backup_dir"
}
