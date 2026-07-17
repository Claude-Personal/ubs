#!/usr/bin/env bash

# Transactional Universal Build Script installer.
# The Bash surface stays curl-friendly; Python owns staging, verification,
# no-follow path checks, atomic replacement, and rollback.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: Universal Build Script installer requires Python 3.9+." >&2
  exit 1
}

exec python3 - "$@" <<'PY'
from __future__ import annotations

import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import stat
import tempfile
import time
from typing import Dict, List, Optional, Tuple
from urllib.parse import urljoin
from urllib.request import Request, urlopen


VERSION = "3.7.1"
REPOSITORY = "https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script"
RELEASE_REF = os.environ.get("UBS_INSTALL_REF", f"v{VERSION}")
BASE_URL = os.environ.get("UBS_INSTALL_BASE_URL", f"{REPOSITORY}/{RELEASE_REF}").rstrip("/") + "/"
ALLOW_FILE = os.environ.get("UBS_INSTALL_ALLOW_FILE", "false") == "true"
FORCE = os.environ.get("UBS_FORCE", "false") == "true"
MANAGE_GITIGNORE = os.environ.get("UBS_MANAGE_GITIGNORE", "true") == "true"
ROOT = Path.cwd().resolve()

MANAGED = (
    "VERSION", "build.sh", "install.sh", "scripts/ubs.py", "scripts/ubs_mcp.py",
    "scripts/bootstrap-update.sh", "scripts/build-rust-helper.sh",
    "native/ubs-helper/Cargo.toml", "native/ubs-helper/Cargo.lock",
    "native/ubs-helper/src/main.rs", "scripts/FLUTTER_VERSION",
    "scripts/TAURI_VERSION", "scripts/build-flutter.sh",
    "scripts/build-tauri.sh", "scripts/build-tauri-macos.sh",
    "scripts/build-gradle.sh", "scripts/build-node.sh",
    "scripts/lib/detect.sh", "scripts/lib/audit.sh",
    "scripts/lib/node-package-manager.sh", "scripts/lib/update.sh",
    "skills/universal-build/SKILL.md", "skills/universal-build/agents/openai.yaml",
    "skills/universal-build/references/optimization.md",
    "templates/flutter/ExportOptions.plist",
)

IGNORE_BLOCK = """# BEGIN Universal Build Script
.ubs/
.env
.env.*
!.env.example
!.env.*.example
signing/
*.p12
*.p8
*.pem
*.key
*.cer
*.mobileprovision
*.provisionprofile
*.entitlements
*.jks
*.keystore
key.properties
local.properties
GoogleService-Info.plist
google-services.json
# END Universal Build Script
"""


def fetch(relative: str) -> bytes:
    if BASE_URL.startswith("file://") and not ALLOW_FILE:
        raise RuntimeError("file:// install source is allowed only in explicit test mode")
    if not (BASE_URL.startswith("https://") or BASE_URL.startswith("file://")):
        raise RuntimeError(f"install source must use HTTPS: {BASE_URL}")
    url = urljoin(BASE_URL, relative)
    last_error: Optional[Exception] = None
    for attempt in range(3):
        try:
            request = Request(url, headers={"User-Agent": f"universal-build-script/{VERSION}"})
            with urlopen(request, timeout=30) as response:
                return response.read()
        except Exception as error:
            last_error = error
            if attempt < 2:
                time.sleep(0.25 * (attempt + 1))
    raise RuntimeError(f"download failed: {relative}: {last_error}")


def parse_manifest(data: bytes) -> Dict[str, str]:
    version = ""
    entries: Dict[str, str] = {}
    for number, raw in enumerate(data.decode("utf-8").splitlines(), 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#"):
            continue
        if fields[0] == "version" and len(fields) == 2:
            version = fields[1]
            continue
        if len(fields) != 3 or fields[0] != "file":
            raise RuntimeError(f"invalid manifest line {number}")
        digest, relative = fields[1:]
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise RuntimeError(f"invalid SHA-256 on manifest line {number}")
        if relative in entries:
            raise RuntimeError(f"duplicate manifest path: {relative}")
        entries[relative] = digest
    if version != VERSION:
        raise RuntimeError(f"installer/manifest version mismatch: {VERSION} != {version}")
    if set(entries) != set(MANAGED):
        missing = sorted(set(MANAGED) - set(entries))
        extra = sorted(set(entries) - set(MANAGED))
        raise RuntimeError(f"managed manifest mismatch: missing={missing} extra={extra}")
    return entries


def safe_relative(relative: str) -> PurePosixPath:
    path = PurePosixPath(relative)
    if not relative or path.is_absolute() or any(part in {"", ".", ".."} for part in path.parts):
        raise RuntimeError(f"unsafe install path: {relative}")
    return path


def destination_for(relative: str) -> Path:
    path = safe_relative(relative)
    current = ROOT
    for part in path.parts:
        current = current / part
        if current.is_symlink():
            raise RuntimeError(f"refusing symbolic-link install path: {relative}")
    return current


def atomic_write(destination: Path, data: bytes, mode: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination_for(destination.relative_to(ROOT).as_posix())
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.ubs-install-", dir=destination.parent,
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        destination_for(destination.relative_to(ROOT).as_posix())
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            temporary.unlink()


def project_type() -> str:
    if (ROOT / "src-tauri" / "tauri.conf.json").is_file():
        return "tauri"
    pubspec = ROOT / "pubspec.yaml"
    if pubspec.is_file() and re.search(
        r"sdk:\s*flutter|^\s*flutter:", pubspec.read_text(encoding="utf-8", errors="replace"), re.MULTILINE,
    ):
        return "flutter"
    if any((ROOT / name).is_file() for name in ("gradlew", "settings.gradle", "settings.gradle.kts")):
        return "gradle"
    package = ROOT / "package.json"
    if package.is_file() and re.search(r'"build"\s*:', package.read_text(encoding="utf-8", errors="replace")):
        return "node"
    return "workspace"


def add_change(
    changes: Dict[str, Tuple[bytes, int]], relative: str, data: bytes,
    mode: int = 0o644, preserve: bool = False,
) -> None:
    destination = destination_for(relative)
    if preserve and destination.exists():
        return
    changes[relative] = (data, mode)


def apply_transaction(changes: Dict[str, Tuple[bytes, int]]) -> None:
    backups: Dict[str, Optional[Tuple[bytes, int]]] = {}
    applied: List[str] = []
    for relative in changes:
        destination = destination_for(relative)
        if destination.exists():
            if not destination.is_file():
                raise RuntimeError(f"install destination is not a file: {relative}")
            backups[relative] = (destination.read_bytes(), stat.S_IMODE(destination.stat().st_mode))
        else:
            backups[relative] = None
    try:
        for relative, (data, mode) in changes.items():
            atomic_write(destination_for(relative), data, mode)
            applied.append(relative)
            print(f"installed: {relative}")
    except Exception:
        for relative in reversed(applied):
            destination = destination_for(relative)
            backup = backups[relative]
            if backup is None:
                if destination.exists():
                    destination.unlink()
            else:
                atomic_write(destination, backup[0], backup[1])
        raise


def main() -> None:
    kind = project_type()
    print(f"Universal Build Script {VERSION} transactional installer ({kind})")
    print(f"source: {BASE_URL}")

    manifest = parse_manifest(fetch("scripts/update-manifest.txt"))
    staged: Dict[str, bytes] = {}
    for relative in MANAGED:
        data = fetch(relative)
        actual = hashlib.sha256(data).hexdigest()
        if actual != manifest[relative]:
            raise RuntimeError(f"SHA-256 mismatch: {relative}")
        staged[relative] = data

    changes: Dict[str, Tuple[bytes, int]] = {}
    for relative in MANAGED:
        destination = destination_for(relative)
        if destination.is_file() and not FORCE:
            print(f"preserved: {relative} (set UBS_FORCE=true to replace)")
            continue
        mode = 0o755 if relative.endswith(".sh") or relative in {
            "scripts/ubs.py", "scripts/ubs_mcp.py",
        } else 0o644
        add_change(changes, relative, staged[relative], mode)

    if MANAGE_GITIGNORE:
        gitignore = destination_for(".gitignore")
        existing = gitignore.read_text(encoding="utf-8") if gitignore.is_file() else ""
        pattern = re.compile(
            r"(?ms)^# BEGIN Universal Build Script\n.*?^# END Universal Build Script\n?"
        )
        if pattern.search(existing):
            updated = pattern.sub(IGNORE_BLOCK, existing)
        else:
            updated = existing.rstrip() + ("\n\n" if existing.strip() else "") + IGNORE_BLOCK
        if updated != existing:
            add_change(changes, ".gitignore", updated.encode(), 0o644)

    if kind == "flutter":
        env_example = fetch(".env.example")
        add_change(changes, ".env.example", env_example, preserve=True)
        if not (ROOT / ".env").exists() and not (ROOT / ".env.prod").exists():
            add_change(changes, ".env", env_example)
        if (ROOT / "ios").is_dir():
            add_change(
                changes, "ios/ExportOptions.plist",
                staged["templates/flutter/ExportOptions.plist"], preserve=True,
            )
    elif kind == "tauri":
        env_example = fetch(".env.macos.example")
        add_change(changes, ".env.macos.example", env_example, preserve=True)
        if not (ROOT / ".env.macos").exists():
            add_change(changes, ".env.macos", env_example, 0o600)

    apply_transaction(changes)
    if kind == "tauri":
        signing = destination_for("signing/.keep").parent
        signing.mkdir(parents=True, exist_ok=True)

    if os.environ.get("UBS_BUILD_RUST_HELPER", "false") == "true":
        import subprocess
        subprocess.run(["bash", "scripts/build-rust-helper.sh"], check=True)

    print("installation complete")
    print("detect: ./build.sh detect")
    print("build:  ./build.sh")


try:
    main()
except Exception as error:
    print(f"installation failed: {error}", file=__import__("sys").stderr)
    raise SystemExit(1)
PY
