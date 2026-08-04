#!/usr/bin/env bash

# 언어별 printf/format placeholder 개수(및 이름)가 en 기준과 어긋나도
# 잡을 자동 테스트가 없다는 문제(#59)에 대한 회귀 테스트.
#
# 1) scripts/lib/i18n_messages.sh: 각 키의 ko/en/ja/zh 값에서 %s 개수가
#    서로 일치하는지 전수 검사한다(ubs_msg는 printf로 넘기므로 개수가
#    안 맞으면 런타임에 깨진다).
# 2) scripts/i18n_messages.py: 각 키의 ko/en/ja/zh 값에서 {name} placeholder
#    이름 집합이 서로 일치하는지 전수 검사한다(.format(**kwargs)는 이름까지
#    맞아야 깨지지 않는다).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- 1) bash 카탈로그: %s 개수 일치 검사 ---

# shellcheck source=/dev/null
source "$ROOT/scripts/lib/i18n_messages.sh"

# macOS 기본 bash(3.2)에는 mapfile/readarray가 없어 word-splitting 배열
# 대입을 쓴다. 키 이름은 [A-Z0-9_]만 포함하므로 공백 분리로도 안전하다.
BASH_KEYS=($(
  compgen -v | grep -E '^UBS_MSG_(ko|en|ja|zh)_' | sed -E 's/^UBS_MSG_(ko|en|ja|zh)_//' | sort -u
))

BASH_FAILURES=()
for key in "${BASH_KEYS[@]}"; do
  first_lang=""
  first_count=""
  for lang in ko en ja zh; do
    varname="UBS_MSG_${lang}_${key}"
    if [ -z "${!varname+x}" ]; then
      BASH_FAILURES+=("$key: $lang 언어 값이 없습니다.")
      continue
    fi
    value="${!varname}"
    # grep -o는 매치가 0개면 exit 1을 내므로(pipefail과 충돌) || true로 흡수한다.
    count="$(grep -o '%s' <<<"$value" | wc -l | tr -d ' ' || true)"
    if [ -z "$first_count" ]; then
      first_lang="$lang"
      first_count="$count"
    elif [ "$count" != "$first_count" ]; then
      BASH_FAILURES+=("$key: %s 개수 불일치 ($first_lang=$first_count, $lang=$count)")
    fi
  done
done

if [ "${#BASH_FAILURES[@]}" -gt 0 ]; then
  echo "scripts/lib/i18n_messages.sh: 언어별 %s placeholder 개수가 일치하지 않는 키가 있습니다." >&2
  printf '  - %s\n' "${BASH_FAILURES[@]}" >&2
  exit 1
fi

# --- 2) python 카탈로그: {name} placeholder 이름 집합 일치 검사 ---

python3 - "$ROOT/scripts" <<'PY'
import string
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from i18n_messages import MESSAGES  # noqa: E402

formatter = string.Formatter()


def field_names(template: str) -> set[str]:
    names = set()
    for _literal, field_name, _spec, _conversion in formatter.parse(template):
        if field_name:
            names.add(field_name)
    return names


failures = []
for key, table in MESSAGES.items():
    langs = [lang for lang in ("ko", "en", "ja", "zh") if lang in table]
    missing = [lang for lang in ("ko", "en", "ja", "zh") if lang not in table]
    for lang in missing:
        failures.append(f"{key}: {lang} 언어 값이 없습니다.")
    if not langs:
        continue
    baseline_lang = langs[0]
    baseline_names = field_names(table[baseline_lang])
    for lang in langs[1:]:
        names = field_names(table[lang])
        if names != baseline_names:
            failures.append(
                f"{key}: {{name}} placeholder 불일치 "
                f"({baseline_lang}={sorted(baseline_names)}, {lang}={sorted(names)})"
            )

if failures:
    print("scripts/i18n_messages.py: 언어별 {name} placeholder가 일치하지 않는 키가 있습니다.",
          file=sys.stderr)
    for line in failures:
        print(f"  - {line}", file=sys.stderr)
    sys.exit(1)
PY

echo "i18n placeholder 일치 테스트 통과"
