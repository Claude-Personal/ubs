#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TYPE="${UBS_PROJECT_TYPE:-gradle}"

if [ -x "./gradlew" ]; then
  GRADLE=("./gradlew")
elif command -v gradle >/dev/null 2>&1; then
  GRADLE=("gradle")
else
  echo -e "${RED}Gradle Wrapper(./gradlew) 또는 gradle 명령이 필요합니다.${NC}" >&2
  exit 1
fi

if [ -n "${UBS_GRADLE_TASK:-}" ]; then
  TASK="$UBS_GRADLE_TASK"
elif [ "$TYPE" = "android" ] && find . -maxdepth 3 -type f \
  \( -name 'build.gradle' -o -name 'build.gradle.kts' \) \
  -exec grep -Eqs 'com\.android\.application' {} + 2>/dev/null; then
  TASK="bundleRelease"
else
  TASK="build"
fi

START_TS=$(date +%s)
echo -e "${CYAN}Gradle 프로젝트 빌드: ${GRADLE[*]} $TASK${NC}"
"${GRADLE[@]}" "$TASK"
ELAPSED=$(($(date +%s) - START_TS))
echo -e "${GREEN}Gradle 빌드 완료 (${ELAPSED}s)${NC}"
