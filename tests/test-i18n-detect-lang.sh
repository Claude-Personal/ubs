#!/usr/bin/env bash

# scripts/lib/i18n.sh의 ubs_detect_lang 자체에 대한 표 기반 단위 테스트(#60).
# LC_ALL > LC_MESSAGES > LANG 폴백 체인, UBS_LANG 최우선, prefix 매칭,
# 미지원 값 처리를 검증한다. python 쪽(_detect_lang)의 동일한 표는
# tests/test_i18n_detect_lang.py에 있다 — 두 알고리즘이 지금 다르게 구현돼
# 있을 수 있는 문제(#54)는 별도이므로 여기서는 bash 구현 자체가 기대 동작을
# 만족하는지만 본다.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT/scripts/lib/i18n.sh" >/dev/null

FAILED=false

# 값이 "UNSET"이면 해당 환경변수를 완전히 unset한다(빈 문자열과는 구분해서
# 취급됨을 검증하기 위함).
run_case() {
  local desc="$1" ubs_lang="$2" lc_all="$3" lc_messages="$4" lang="$5" expected="$6"

  if [ "$ubs_lang" = UNSET ]; then unset UBS_LANG; else export UBS_LANG="$ubs_lang"; fi
  if [ "$lc_all" = UNSET ]; then unset LC_ALL; else export LC_ALL="$lc_all"; fi
  if [ "$lc_messages" = UNSET ]; then unset LC_MESSAGES; else export LC_MESSAGES="$lc_messages"; fi
  if [ "$lang" = UNSET ]; then unset LANG; else export LANG="$lang"; fi

  local actual
  actual="$(ubs_detect_lang)"
  if [ "$actual" != "$expected" ]; then
    echo "[$desc] 기대=$expected 실제=$actual" \
      "(UBS_LANG=$ubs_lang LC_ALL=$lc_all LC_MESSAGES=$lc_messages LANG=$lang)" >&2
    FAILED=true
  fi
}

run_case "UBS_LANG=ko"                     ko    UNSET       UNSET       UNSET       ko
run_case "LANG만 ja_JP.UTF-8"               UNSET UNSET       UNSET       ja_JP.UTF-8 ja
run_case "LANG=C는 en으로 폴백"             UNSET UNSET       UNSET       C           en
run_case "아무것도 없으면 en"               UNSET UNSET       UNSET       UNSET       en
run_case "지원하지 않는 로케일은 en"        UNSET UNSET       UNSET       fr_FR.UTF-8 en
run_case "UBS_LANG이 LANG보다 우선"         en    UNSET       UNSET       ko_KR.UTF-8 en
run_case "LC_ALL이 LANG보다 우선"           UNSET zh_CN.UTF-8 UNSET       ko_KR.UTF-8 zh
run_case "LC_MESSAGES가 LANG보다 우선"      UNSET UNSET       ja_JP.UTF-8 ko_KR.UTF-8 ja
run_case "LC_ALL이 LC_MESSAGES보다 우선"    UNSET zh_TW.UTF-8 ja_JP.UTF-8 ko_KR.UTF-8 zh
run_case "LANG=zh_CN.UTF-8"                 UNSET UNSET       UNSET       zh_CN.UTF-8 zh
run_case "LANG=en_US.UTF-8"                 UNSET UNSET       UNSET       en_US.UTF-8 en
run_case "UBS_LANG 빈 문자열은 미설정 취급" ""    UNSET       UNSET       ja_JP.UTF-8 ja

unset UBS_LANG LC_ALL LC_MESSAGES LANG 2>/dev/null || true

if [ "$FAILED" = true ]; then
  echo "ubs_detect_lang 표 기반 테스트 실패" >&2
  exit 1
fi

echo "ubs_detect_lang 단위 테스트 통과"
