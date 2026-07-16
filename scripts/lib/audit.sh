#!/usr/bin/env bash

# 정적 설정 감사 모듈. 실제 산출물의 역공학 검증이 아니라 빌드 설정과
# Universal Build Script가 적용하는 옵션을 점검한다.

audit_emit() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6"
}

gradle_contains() {
  local dir="$1"
  local pattern="$2"
  find "$dir" -maxdepth 4 -type f \( -name 'build.gradle' -o -name 'build.gradle.kts' \) \
    -exec grep -Eqs "$pattern" {} + 2>/dev/null
}

audit_flutter() {
  local type="$1" dir="$2"
  audit_emit "$type" "$dir" optimization release-build enforced \
    "선택한 모든 출력에 release 빌드와 icon tree shaking을 적용"
  audit_emit "$type" "$dir" obfuscation native-symbols enforced \
    "AAB/APK/IPA에 --obfuscate와 --split-debug-info 적용"
  audit_emit "$type" "$dir" obfuscation web not-supported \
    "Flutter web은 최적화 빌드지만 Dart --obfuscate 대상이 아님"
}

audit_tauri() {
  local type="$1" dir="$2"
  local cargo="$dir/src-tauri/Cargo.toml"
  local package_json="$dir/package.json"

  if [ -f "$cargo" ] && grep -Eqs '^[[:space:]]*lto[[:space:]]*=[[:space:]]*(true|"thin"|"fat")' "$cargo"; then
    audit_emit "$type" "$dir" optimization rust-lto configured "Cargo release LTO 설정 감지"
  else
    audit_emit "$type" "$dir" optimization rust-lto recommended "Cargo.toml release profile의 lto 설정을 검토"
  fi

  if [ -f "$cargo" ] && grep -Eqs '^[[:space:]]*strip[[:space:]]*=[[:space:]]*(true|"symbols"|"debuginfo")' "$cargo"; then
    audit_emit "$type" "$dir" optimization rust-strip configured "Rust strip 설정 감지"
  else
    audit_emit "$type" "$dir" optimization rust-strip recommended "배포 바이너리의 strip 설정을 검토"
  fi

  if [ -f "$package_json" ] && grep -Eqs '"(vite|next|react-scripts)"[[:space:]]*:' "$package_json"; then
    audit_emit "$type" "$dir" optimization frontend-minify framework-default \
      "프런트엔드 도구의 production minify/tree-shaking에 위임"
  else
    audit_emit "$type" "$dir" optimization frontend-minify unknown \
      "프런트엔드 build script의 minify 설정을 수동 확인"
  fi

  if [ "${TAURI_OBFUSCATE_JS:-false}" = "true" ] || \
     { [ -f "$dir/.env.macos" ] && grep -Eqs "^TAURI_OBFUSCATE_JS[[:space:]]*=[[:space:]]*['\"]?true" "$dir/.env.macos"; }; then
    audit_emit "$type" "$dir" obfuscation frontend-js configured \
      "javascript-obfuscator 활성화 감지"
  else
    audit_emit "$type" "$dir" obfuscation frontend-js optional-off \
      "기본 minify만 적용; 추가 JS 난독화는 꺼져 있음"
  fi

  audit_emit "$type" "$dir" obfuscation rust-native compiled \
    "Rust는 release 네이티브 바이너리로 컴파일되며 난독화와 동일 개념은 아님"
}

audit_android() {
  local type="$1" dir="$2"

  if gradle_contains "$dir" '(isMinifyEnabled|minifyEnabled)[[:space:]=]+true'; then
    audit_emit "$type" "$dir" optimization android-minify configured "release minify/R8 활성화 감지"
  else
    audit_emit "$type" "$dir" optimization android-minify not-configured \
      "release minifyEnabled/isMinifyEnabled=true를 확인하지 못함"
  fi

  if gradle_contains "$dir" '(isShrinkResources|shrinkResources)[[:space:]=]+true'; then
    audit_emit "$type" "$dir" optimization resource-shrinking configured "Android resource shrinking 활성화 감지"
  else
    audit_emit "$type" "$dir" optimization resource-shrinking not-configured \
      "release shrinkResources/isShrinkResources=true를 확인하지 못함"
  fi

  if gradle_contains "$dir" 'proguardFiles|proguardFile'; then
    audit_emit "$type" "$dir" obfuscation r8-rules configured "ProGuard/R8 규칙 연결 감지"
  else
    audit_emit "$type" "$dir" obfuscation r8-rules not-configured "ProGuard/R8 규칙 연결을 확인하지 못함"
  fi
}

audit_kotlin() {
  local type="$1" dir="$2"
  audit_emit "$type" "$dir" optimization gradle-release project-specific \
    "기본 build task를 실행하며 최적화 수준은 Gradle 프로젝트 설정에 따름"

  if gradle_contains "$dir" 'proguard|r8|shadowJar|com\.github\.jengelman\.gradle\.plugins\.shadow'; then
    audit_emit "$type" "$dir" obfuscation jvm-obfuscation configured \
      "축소/난독화 관련 Gradle 설정 감지"
  else
    audit_emit "$type" "$dir" obfuscation jvm-obfuscation not-configured \
      "일반 Kotlin/JVM build는 자동 난독화를 보장하지 않음"
  fi
}

audit_node() {
  local type="$1" dir="$2"
  local package_json="$dir/package.json"

  if [ -f "$package_json" ] && grep -Eqs '"(vite|next|react-scripts)"[[:space:]]*:' "$package_json"; then
    audit_emit "$type" "$dir" optimization production-bundle framework-default \
      "production build 도구의 minify/tree-shaking에 위임"
  else
    audit_emit "$type" "$dir" optimization production-bundle unknown \
      "scripts.build가 최적화 빌드인지 수동 확인"
  fi

  if [ -f "$package_json" ] && grep -Eqs 'javascript-obfuscator|webpack-obfuscator|rollup-plugin-obfuscator' "$package_json"; then
    audit_emit "$type" "$dir" obfuscation javascript configured "JS 난독화 패키지 감지"
  else
    audit_emit "$type" "$dir" obfuscation javascript not-configured \
      "minification은 난독화 보장이 아니며 별도 난독화 설정을 확인하지 못함"
  fi
}

audit_project() {
  local type="$1" dir="$2"
  case "$type" in
    flutter) audit_flutter "$type" "$dir" ;;
    tauri) audit_tauri "$type" "$dir" ;;
    android) audit_android "$type" "$dir" ;;
    kotlin|kotlin-multiplatform|gradle) audit_kotlin "$type" "$dir" ;;
    react|next|node) audit_node "$type" "$dir" ;;
  esac
}
