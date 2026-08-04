"""CLI message catalog runtime.

Language resolution: $UBS_LANG > $LC_ALL > $LC_MESSAGES > $LANG > en.
Supported: ko en ja zh. Anything else (including "C"/"POSIX") falls back to en.
"""

from __future__ import annotations

import os

from i18n_messages import MESSAGES

_SUPPORTED = ("ko", "en", "ja", "zh")


def _detect_lang() -> str:
    raw = (
        os.environ.get("UBS_LANG")
        or os.environ.get("LC_ALL")
        or os.environ.get("LC_MESSAGES")
        or os.environ.get("LANG")
        or "en"
    )
    code = raw.split(".")[0].split("_")[0].lower()
    return code if code in _SUPPORTED else "en"


LANG = _detect_lang()


def t(key: str, **kwargs) -> str:
    """Look up KEY in the resolved language, falling back to en, then the key itself."""
    table = MESSAGES.get(key)
    if table is None:
        return key
    template = table.get(LANG) or table.get("en") or key
    return template.format(**kwargs) if kwargs else template
