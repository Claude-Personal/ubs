#!/usr/bin/env bash

# en/ja/zh 실행 경로가 실제로 해당 언어 문구를 렌더링하는지 검증한다.
# 기존 tests/test-*.sh는 전부 UBS_LANG=ko로 고정돼 있어 en/ja/zh가
# 깨져도(#49류 버그) 못 잡는다는 문제(#57)에 대한 회귀 테스트.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 출력($1)에 문구($2)가 없으면 한국어 에러 메시지($3)를 찍고 종료한다.
check_contains() {
  printf '%s\n' "$1" | grep -Fq -- "$2" || {
    echo "$3" >&2
    exit 1
  }
}

# --- 1) bash 진입점(build.sh --help)이 언어별 Usage 문구를 렌더링하는지 ---

EN_HELP="$(UBS_LANG=en bash "$ROOT/build.sh" --help 2>&1)"
check_contains "$EN_HELP" "Usage:" "bash build.sh --help(en)에 'Usage:'가 없습니다."

JA_HELP="$(UBS_LANG=ja bash "$ROOT/build.sh" --help 2>&1)"
check_contains "$JA_HELP" "使い方:" "bash build.sh --help(ja)에 '使い方:'가 없습니다."

ZH_HELP="$(UBS_LANG=zh bash "$ROOT/build.sh" --help 2>&1)"
check_contains "$ZH_HELP" "用法:" "bash build.sh --help(zh)에 '用法:'가 없습니다."

# --- 2) python 진입점(scripts/ubs.py --help, USAGE_TEXT)이 언어별로 렌더링되는지 ---

EN_PY_HELP="$(UBS_LANG=en python3 "$ROOT/scripts/ubs.py" --help 2>&1)"
check_contains "$EN_PY_HELP" "Usage:" "python ubs.py --help(en)에 'Usage:'가 없습니다."

JA_PY_HELP="$(UBS_LANG=ja python3 "$ROOT/scripts/ubs.py" --help 2>&1)"
check_contains "$JA_PY_HELP" "使い方:" "python ubs.py --help(ja)에 '使い方:'가 없습니다."

ZH_PY_HELP="$(UBS_LANG=zh python3 "$ROOT/scripts/ubs.py" --help 2>&1)"
check_contains "$ZH_PY_HELP" "用法:" "python ubs.py --help(zh)에 '用法:'가 없습니다."

# --- 3) 비대화형 실행 경로(--dry-run --all, 이 레포 자체를 대상)도 언어별로 렌더링되는지 ---
# 이 레포 루트에는 빌드 가능한 프로젝트가 없어 명령 자체는 exit 1이지만
# (의도된 동작), 여기서는 언어별 출력 문구만 검증하므로 exit 코드는 무시한다.

EN_RUN="$(UBS_NON_INTERACTIVE=true UBS_LANG=en bash "$ROOT/build.sh" --dry-run --all "$ROOT" 2>&1 || true)"
check_contains "$EN_RUN" "No projects match the given conditions." \
  "비대화형 dry-run(en) 출력에 예상 문구가 없습니다."

JA_RUN="$(UBS_NON_INTERACTIVE=true UBS_LANG=ja bash "$ROOT/build.sh" --dry-run --all "$ROOT" 2>&1 || true)"
check_contains "$JA_RUN" "条件に一致するプロジェクトがありません。" \
  "비대화형 dry-run(ja) 출력에 예상 문구가 없습니다."

ZH_RUN="$(UBS_NON_INTERACTIVE=true UBS_LANG=zh bash "$ROOT/build.sh" --dry-run --all "$ROOT" 2>&1 || true)"
check_contains "$ZH_RUN" "没有符合条件的项目。" \
  "비대화형 dry-run(zh) 출력에 예상 문구가 없습니다."

# --- 4) 인터랙티브 메뉴 번호-내용 정합성: 언어별 헤더/옵션 문구가 맞고,
#        "2"번을 고르면 언어와 무관하게 같은 값으로 매핑되는지 ---

python3 - "$ROOT/scripts/ubs.py" <<'PY'
import importlib.util
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock

ubs_path = sys.argv[1]
sys.path.insert(0, str(Path(ubs_path).parent))

# (lang, 헤더 문구 일부, 1번 옵션 문구 일부, 2번 옵션 문구 일부)
CASES = [
    ("en", "This is your first build", "Unattended build", "Interactive build"),
    ("ja", "初回のビルドですね", "無人ビルド", "対話型ビルド"),
    ("zh", "这是您的首次构建", "无人值守构建", "交互式构建"),
]

for lang, header_snippet, option1_snippet, option2_snippet in CASES:
    os.environ["UBS_LANG"] = lang
    for mod_name in ("i18n", "i18n_messages", "ubs"):
        sys.modules.pop(mod_name, None)
    spec = importlib.util.spec_from_file_location("ubs", ubs_path)
    ubs = importlib.util.module_from_spec(spec)
    sys.modules["ubs"] = ubs
    spec.loader.exec_module(ubs)

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        mock_sys = mock.Mock(wraps=ubs.sys)
        mock_sys.stdin.isatty.return_value = True
        mock_sys.stdout.isatty.return_value = True
        printed = []
        with mock.patch.object(ubs, "sys", mock_sys), \
                mock.patch("builtins.input", return_value="2"), \
                mock.patch("builtins.print",
                            side_effect=lambda *a, **k: printed.append(" ".join(str(x) for x in a))):
            result = ubs.resolve_non_interactive_default(root)
        output = "\n".join(printed)
        assert header_snippet in output, f"[{lang}] 메뉴 헤더 문구를 찾지 못했습니다: {output!r}"
        assert option1_snippet in output, f"[{lang}] 1번 옵션 문구를 찾지 못했습니다: {output!r}"
        assert option2_snippet in output, f"[{lang}] 2번 옵션 문구를 찾지 못했습니다: {output!r}"
        # option_1=Unattended, option_2=Interactive, invert=True 이므로
        # "2"(대화형) 선택 시 non_interactive_default는 언어와 무관하게 False여야 한다.
        assert result is False, f"[{lang}] 2번 선택 결과가 False가 아닙니다: {result!r}"
PY

echo "i18n 실행 경로 테스트 통과"
