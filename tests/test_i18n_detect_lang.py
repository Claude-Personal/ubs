#!/usr/bin/env python3
"""scripts/i18n.py의 _detect_lang 자체에 대한 표 기반 단위 테스트(#60).

LC_ALL > LC_MESSAGES > LANG 폴백 체인, UBS_LANG 최우선, prefix 매칭,
미지원 값 처리를 검증한다. bash 쪽(ubs_detect_lang)의 동일한 표는
tests/test-i18n-detect-lang.sh에 있다 — 두 알고리즘이 지금 다르게 구현돼
있을 수 있는 문제(#54)는 별도이므로 여기서는 python 구현 자체가 기대 동작을
만족하는지만 본다.
"""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import i18n  # noqa: E402

UNSET = object()

_ENV_NAMES = ("UBS_LANG", "LC_ALL", "LC_MESSAGES", "LANG")

# (설명, UBS_LANG, LC_ALL, LC_MESSAGES, LANG, 기대값)
CASES = [
    ("UBS_LANG=ko", "ko", UNSET, UNSET, UNSET, "ko"),
    ("LANG만 ja_JP.UTF-8", UNSET, UNSET, UNSET, "ja_JP.UTF-8", "ja"),
    ("LANG=C는 en으로 폴백", UNSET, UNSET, UNSET, "C", "en"),
    ("아무것도 없으면 en", UNSET, UNSET, UNSET, UNSET, "en"),
    ("지원하지 않는 로케일은 en", UNSET, UNSET, UNSET, "fr_FR.UTF-8", "en"),
    ("UBS_LANG이 LANG보다 우선", "en", UNSET, UNSET, "ko_KR.UTF-8", "en"),
    ("LC_ALL이 LANG보다 우선", UNSET, "zh_CN.UTF-8", UNSET, "ko_KR.UTF-8", "zh"),
    ("LC_MESSAGES가 LANG보다 우선", UNSET, UNSET, "ja_JP.UTF-8", "ko_KR.UTF-8", "ja"),
    ("LC_ALL이 LC_MESSAGES보다 우선", UNSET, "zh_TW.UTF-8", "ja_JP.UTF-8", "ko_KR.UTF-8", "zh"),
    ("LANG=zh_CN.UTF-8", UNSET, UNSET, UNSET, "zh_CN.UTF-8", "zh"),
    ("LANG=en_US.UTF-8", UNSET, UNSET, UNSET, "en_US.UTF-8", "en"),
    ("UBS_LANG 빈 문자열은 미설정 취급", "", UNSET, UNSET, "ja_JP.UTF-8", "ja"),
]


class DetectLangTests(unittest.TestCase):
    def test_table(self) -> None:
        for desc, ubs_lang, lc_all, lc_messages, lang, expected in CASES:
            row = dict(zip(_ENV_NAMES, (ubs_lang, lc_all, lc_messages, lang)))
            overrides = {name: value for name, value in row.items() if value is not UNSET}
            removed = [name for name, value in row.items() if value is UNSET]
            with self.subTest(desc):
                with mock.patch.dict(os.environ, overrides, clear=False):
                    for name in removed:
                        os.environ.pop(name, None)
                    actual = i18n._detect_lang()
                    self.assertEqual(
                        actual, expected,
                        f"[{desc}] 기대={expected!r} 실제={actual!r} (env={row})",
                    )


if __name__ == "__main__":
    unittest.main()
