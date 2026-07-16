#!/usr/bin/env python3
"""Universal Build Script orchestration core.

Bash remains the stable entry point and ecosystem adapters remain intentionally
small shell programs. This module owns structured parsing, discovery, audits,
planning, process orchestration, JSON output, and build reports.
"""

from __future__ import annotations

import datetime as dt
from concurrent.futures import as_completed, ThreadPoolExecutor
from functools import lru_cache
import glob
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Sequence, Set


RUNTIME_ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {
    ".git", "node_modules", "build", "dist", "target", ".gradle",
    ".dart_tool", ".next", ".ubs",
}
FLUTTER_PLATFORM_DIRS = {"android", "ios", "macos", "linux", "windows", "web"}
GRADLE_NAMES = {"build.gradle", "build.gradle.kts"}
NODE_LOCKS = (
    "pnpm-lock.yaml", "yarn.lock", "bun.lock", "bun.lockb",
    "package-lock.json", "npm-shrinkwrap.json",
)
NODE_CONFIGS = (
    ".npmrc", ".yarnrc", ".yarnrc.yml", "pnpm-workspace.yaml",
    "pnpmfile.cjs", ".pnpmfile.cjs", ".node-version", ".nvmrc",
)
MARKER_NAMES = {
    "pubspec.yaml", "tauri.conf.json", "settings.gradle",
    "settings.gradle.kts", "package.json",
}
ADAPTERS = {
    "tauri": "scripts/build-tauri.sh",
    "flutter": "scripts/build-flutter.sh",
    "android": "scripts/ubs.py#gradle",
    "kotlin-multiplatform": "scripts/ubs.py#gradle",
    "kotlin": "scripts/ubs.py#gradle",
    "gradle": "scripts/ubs.py#gradle",
    "react": "scripts/ubs.py#node",
    "next": "scripts/ubs.py#node",
    "node": "scripts/ubs.py#node",
}
PYTHON_ADAPTER_TYPES = {
    "android", "kotlin-multiplatform", "kotlin", "gradle",
    "react", "next", "node",
}

GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
CYAN = "\033[0;36m"
NC = "\033[0m"


USAGE = """Universal Build Script

사용법:
  ./build.sh                         자동 감지 + 안전한 기본값으로 무인 빌드
  ./build.sh detect [경로]           하위 프로젝트 탐색
  ./build.sh detect --json [경로]    AI/MCP용 감지 결과 JSON
  ./build.sh audit [경로]            최적화·난독화 설정 감사
  ./build.sh audit --json [경로]     AI/MCP용 감사 결과 JSON
  ./build.sh plan [경로]             읽기 전용 빌드 계획
  ./build.sh plan --json [경로]      AI/MCP용 빌드 계획 JSON
  ./build.sh update --check [--json] 전체 런타임 업데이트 확인
  ./build.sh update --dry-run        변경 파일 미리 보기
  ./build.sh update                  검증·백업 후 안전 업데이트
  ./build.sh update --prune-backups 30  30일 지난 업데이트 백업 삭제
  ./build.sh --dry-run               실행할 빌드만 미리 확인
  ./build.sh --interactive           버전과 플랫폼을 직접 선택
  ./build.sh build --project <경로>  지정 프로젝트 빌드
  ./build.sh build --all --type TYPE 특정 타입만 빌드

주요 옵션:
  --version-bump none|build|patch|minor|major
  --flutter-platform auto|all|ios|android
  --flutter-outputs auto|appbundle,apk,ipa,web
  --clean | --skip-clean
  --fail-fast
  --jobs N                            독립 프로젝트 제한 병렬 빌드
  --report-json <파일>               실제 빌드 결과 JSON 저장

지원 타입:
  tauri, flutter, android, kotlin-multiplatform, kotlin, gradle,
  react, next, node
"""


@dataclass(frozen=True)
class Project:
    type: str
    path: Path


@dataclass
class Options:
    command: str = "build"
    root: Path = Path.cwd()
    build_all: bool = False
    dry_run: bool = False
    json_output: bool = False
    non_interactive: bool = os.environ.get("UBS_NON_INTERACTIVE", "true") == "true"
    skip_clean: bool = os.environ.get("UBS_SKIP_CLEAN", "true") == "true"
    fail_fast: bool = False
    version_bump: str = os.environ.get("UBS_VERSION_BUMP", "none")
    flutter_platform: str = os.environ.get("UBS_FLUTTER_PLATFORM", "auto")
    flutter_outputs: str = os.environ.get("UBS_FLUTTER_OUTPUTS", "auto")
    type_filter: str = ""
    project_path: Optional[Path] = None
    report_json: Optional[Path] = None
    jobs: int = field(default_factory=lambda: int(os.environ.get("UBS_JOBS", "1")))
    update_check: bool = False
    update_prune_days: Optional[int] = None


def eprint(message: str) -> None:
    print(message, file=sys.stderr)


def canonical_dir(value: Path) -> Path:
    path = value.expanduser().resolve(strict=True)
    if not path.is_dir():
        raise ValueError(str(value))
    return path


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def dotenv_value(path: Path, key: str) -> str:
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        candidate, value = line.split("=", 1)
        if candidate.strip() != key:
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        return value
    return ""


def gradle_files(directory: Path, max_depth: int = 3) -> List[Path]:
    files: List[Path] = []
    base_depth = len(directory.parts)
    for root, dirs, names in os.walk(directory):
        current = Path(root)
        depth = len(current.parts) - base_depth
        dirs[:] = [] if depth >= max_depth else [name for name in dirs if name not in EXCLUDED_DIRS]
        files.extend(current / name for name in names if name in GRADLE_NAMES)
    return files


@lru_cache(maxsize=256)
def catalog_plugin_accessors(directory: Path) -> Dict[str, Set[str]]:
    plugins: Dict[str, Set[str]] = {}
    catalog = directory / "gradle" / "libs.versions.toml"
    in_plugins = False
    for line in read_text(catalog).splitlines():
        stripped = line.strip()
        if stripped.startswith("["):
            in_plugins = stripped == "[plugins]"
            continue
        if not in_plugins or not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        match = re.search(r"\bid\s*=\s*[\"']([^\"']+)", value)
        if not match:
            match = re.search(r"^\s*[\"']([^\"']+)[\"']", value)
        if not match:
            continue
        accessor = re.sub(r"[-_.]+", ".", key.strip())
        plugins.setdefault(match.group(1), set()).add(accessor)
    return plugins


def uses_catalog_plugin(gradle_text: str, accessors: Iterable[str]) -> bool:
    return any(re.search(
        rf"alias\s*\(\s*libs\.plugins\.{re.escape(accessor)}\s*\)",
        gradle_text,
    ) for accessor in accessors)


@lru_cache(maxsize=256)
def gradle_evidence(directory: Path, max_depth: int = 3) -> tuple[str, Dict[str, Set[str]]]:
    combined = "\n".join(read_text(path) for path in gradle_files(directory, max_depth))
    return combined, catalog_plugin_accessors(directory)


def has_gradle_plugin(directory: Path, plugin_id: str) -> bool:
    combined, catalog = gradle_evidence(directory)
    if re.search(rf"[\"']?{re.escape(plugin_id)}[\"']?", combined):
        return True
    return uses_catalog_plugin(combined, catalog.get(plugin_id, set()))


def detect_gradle_type(directory: Path) -> Optional[str]:
    combined, catalog = gradle_evidence(directory)
    if not combined:
        return None
    if re.search(r"com\.android\.(application|library)", combined) or any(
        uses_catalog_plugin(combined, catalog.get(plugin_id, set()))
        for plugin_id in ("com.android.application", "com.android.library")
    ):
        return "android"
    if re.search(r"multiplatform|org\.jetbrains\.kotlin\.multiplatform", combined) or \
            uses_catalog_plugin(combined, catalog.get("org.jetbrains.kotlin.multiplatform", set())):
        return "kotlin-multiplatform"
    if re.search(r"org\.jetbrains\.kotlin|kotlin.*(jvm|android)", combined) or any(
        uses_catalog_plugin(combined, accessors)
        for plugin_id, accessors in catalog.items()
        if plugin_id.startswith("org.jetbrains.kotlin")
    ):
        return "kotlin"
    return "gradle"


def read_package(directory: Path) -> dict:
    try:
        value = json.loads((directory / "package.json").read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def is_node_workspace(directory: Path) -> bool:
    package = read_package(directory)
    return bool(
        any((directory / name).is_file() for name in NODE_LOCKS)
        or (directory / "pnpm-workspace.yaml").is_file()
        or isinstance(package.get("workspaces"), (list, dict))
        or isinstance(package.get("packageManager"), str)
    )


@lru_cache(maxsize=512)
def node_workspace_root(directory: Path) -> Path:
    directory = directory.resolve()
    fallback = directory
    for current in (directory, *directory.parents):
        if current != directory and is_node_workspace(current):
            return current
        if (current / ".git").exists():
            break
    return fallback


def detect_node_package_manager(directory: Path) -> str:
    workspace = node_workspace_root(directory)
    declared = read_package(workspace).get("packageManager", "")
    if isinstance(declared, str):
        manager = declared.split("@", 1)[0]
        if manager in {"npm", "pnpm", "yarn", "bun"}:
            return manager
    if (workspace / "pnpm-lock.yaml").is_file():
        return "pnpm"
    if (workspace / "yarn.lock").is_file():
        return "yarn"
    if (workspace / "bun.lock").is_file() or (workspace / "bun.lockb").is_file():
        return "bun"
    return "npm"


def command_version(command: str, environment: Dict[str, str]) -> str:
    executable = shutil.which(command, path=environment.get("PATH"))
    if not executable:
        return "missing"
    try:
        result = subprocess.run(
            [executable, "--version"], env=environment, check=False,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=5,
        )
        return result.stdout.strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def dependency_inputs(workspace: Path) -> List[Path]:
    inputs = []
    for name in ("package.json", *NODE_LOCKS, *NODE_CONFIGS):
        path = workspace / name
        if path.is_file():
            inputs.append(path)
    for pattern in ("**/package.json", "patches/**/*", ".yarn/patches/**/*"):
        for path in workspace.glob(pattern):
            if path.is_file() and not any(part in EXCLUDED_DIRS for part in path.relative_to(workspace).parts):
                inputs.append(path)
    return sorted(set(inputs), key=lambda path: path.as_posix())


def dependency_digest(
    workspace: Path, manager: str, environment: Optional[Dict[str, str]] = None,
) -> str:
    environment = environment or os.environ.copy()
    digest = hashlib.sha256()
    runtime = {
        "manager": manager,
        "manager_version": command_version(manager, environment),
        "node_version": command_version("node", environment),
        "platform": platform.system(),
        "machine": platform.machine(),
    }
    digest.update(json.dumps(runtime, sort_keys=True).encode())
    for path in dependency_inputs(workspace):
        digest.update(path.relative_to(workspace).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def node_install_command(directory: Path, manager: str) -> List[str]:
    if manager == "pnpm":
        return ["pnpm", "install", "--frozen-lockfile"] if (directory / "pnpm-lock.yaml").is_file() else ["pnpm", "install"]
    if manager == "yarn":
        if (directory / ".yarnrc.yml").is_file():
            return ["yarn", "install", "--immutable"]
        return ["yarn", "install", "--frozen-lockfile"] if (directory / "yarn.lock").is_file() else ["yarn", "install"]
    if manager == "bun":
        locked = (directory / "bun.lock").is_file() or (directory / "bun.lockb").is_file()
        return ["bun", "install", "--frozen-lockfile"] if locked else ["bun", "install"]
    locked = (directory / "package-lock.json").is_file() or (directory / "npm-shrinkwrap.json").is_file()
    return ["npm", "ci", "--no-fund", "--no-audit"] if locked else ["npm", "install", "--no-fund", "--no-audit"]


def run_command(command: Sequence[str], directory: Path, environment: Dict[str, str]) -> int:
    return subprocess.run(list(command), cwd=directory, env=environment, check=False).returncode


def install_node_dependencies(workspace: Path, manager: str, environment: Dict[str, str]) -> int:
    if environment.get("UBS_SKIP_INSTALL", "false") == "true":
        print(f"{CYAN}Node 의존성 설치를 건너뜁니다 (UBS_SKIP_INSTALL=true).{NC}")
        return 0
    mode = environment.get("UBS_INSTALL_MODE", "auto")
    if mode not in {"auto", "always"}:
        eprint(f"{RED}UBS_INSTALL_MODE은 auto 또는 always여야 합니다: {mode}{NC}")
        return 2
    stamp = workspace / "node_modules" / ".ubs-install-sha256"
    expected = dependency_digest(workspace, manager, environment)
    if mode == "auto" and read_text(stamp).strip() == expected:
        print(f"{CYAN}의존성 입력이 변경되지 않아 {manager} install을 생략합니다.{NC}")
        return 0
    status = run_command(node_install_command(workspace, manager), workspace, environment)
    if status == 0:
        stamp.parent.mkdir(parents=True, exist_ok=True)
        stamp.write_text(expected + "\n", encoding="utf-8")
    return status


def run_node_adapter(directory: Path, environment: Dict[str, str]) -> int:
    workspace = node_workspace_root(directory)
    manager = detect_node_package_manager(directory)
    if shutil.which(manager, path=environment.get("PATH")) is None:
        eprint(f"{RED}{manager} 패키지 매니저가 필요합니다.{NC}")
        return 1
    script = environment.get("UBS_NODE_BUILD_SCRIPT", "build")
    started = time.monotonic()
    print(f"{CYAN}Node 프로젝트 빌드 ({manager}, script={script}){NC}")
    if workspace != directory:
        print(f"{CYAN}Node workspace root: {workspace}{NC}")
    status = install_node_dependencies(workspace, manager, environment)
    if status == 0:
        status = run_command([manager, "run", script], directory, environment)
    if status == 0:
        print(f"{GREEN}Node 빌드 완료 ({int(time.monotonic() - started)}s){NC}")
    return status


def gradle_command(directory: Path) -> Optional[List[str]]:
    wrapper = directory / "gradlew"
    if wrapper.is_file() and os.access(wrapper, os.X_OK):
        return [str(wrapper)]
    windows_wrapper = directory / "gradlew.bat"
    if os.name == "nt" and windows_wrapper.is_file():
        return ["cmd", "/c", str(windows_wrapper)]
    executable = shutil.which("gradle")
    return [executable] if executable else None


def split_cli_arguments(value: str, windows: Optional[bool] = None) -> List[str]:
    if not value:
        return []
    windows = os.name == "nt" if windows is None else windows
    arguments = shlex.split(value, posix=not windows)
    if windows:
        return [
            argument[1:-1]
            if len(argument) >= 2 and argument[0] == argument[-1] and argument[0] in "\"'"
            else argument
            for argument in arguments
        ]
    return arguments


def resolved_gradle_arguments(kind: str, directory: Path, environment: Dict[str, str]) -> List[str]:
    task_value = environment.get("UBS_GRADLE_TASK", "")
    if task_value:
        tasks = split_cli_arguments(task_value)
    elif kind == "android" and has_gradle_plugin(directory, "com.android.application"):
        tasks = ["bundleRelease"]
    else:
        tasks = ["build"]
    flags = split_cli_arguments(environment.get("UBS_GRADLE_FLAGS", ""))
    if environment.get("UBS_GRADLE_OPTIMIZE", "false") == "true":
        flags = ["--build-cache", "--parallel", *flags]
    return [*tasks, *flags]


def run_gradle_adapter(kind: str, directory: Path, environment: Dict[str, str]) -> int:
    command = gradle_command(directory)
    if not command:
        eprint(f"{RED}Gradle Wrapper 또는 gradle 명령이 필요합니다.{NC}")
        return 1
    full_command = [*command, *resolved_gradle_arguments(kind, directory, environment)]
    started = time.monotonic()
    print(f"{CYAN}Gradle 프로젝트 빌드: {' '.join(full_command)}{NC}")
    status = run_command(full_command, directory, environment)
    if status == 0:
        print(f"{GREEN}Gradle 빌드 완료 ({int(time.monotonic() - started)}s){NC}")
    return status


def run_python_adapter(kind: str, directory: Path, environment: Dict[str, str]) -> int:
    if kind in {"react", "next", "node"}:
        return run_node_adapter(directory, environment)
    if kind in {"android", "kotlin-multiplatform", "kotlin", "gradle"}:
        return run_gradle_adapter(kind, directory, environment)
    raise ValueError(f"Python adapter가 지원하지 않는 타입입니다: {kind}")


@lru_cache(maxsize=512)
def load_package(directory: Path) -> Optional[dict]:
    try:
        value = json.loads((directory / "package.json").read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else None
    except (OSError, json.JSONDecodeError):
        return None


def package_dependencies(package: dict) -> Dict[str, object]:
    dependencies: Dict[str, object] = {}
    for key in ("dependencies", "devDependencies"):
        value = package.get(key)
        if isinstance(value, dict):
            dependencies.update(value)
    return dependencies


@lru_cache(maxsize=512)
def detect_project_type(directory: Path) -> Optional[str]:
    if (directory / "src-tauri" / "tauri.conf.json").is_file():
        return "tauri"
    pubspec = directory / "pubspec.yaml"
    if pubspec.is_file() and re.search(r"sdk:\s*flutter|^\s*flutter:", read_text(pubspec), re.MULTILINE):
        return "flutter"
    gradle_markers = (
        "gradlew", "settings.gradle", "settings.gradle.kts",
        "build.gradle", "build.gradle.kts",
    )
    if any((directory / marker).is_file() for marker in gradle_markers):
        return detect_gradle_type(directory)
    package = load_package(directory)
    scripts = package.get("scripts") if package is not None else None
    if package is not None and isinstance(scripts, dict) and isinstance(scripts.get("build"), str):
        dependencies = package_dependencies(package)
        if "next" in dependencies:
            return "next"
        if "react" in dependencies:
            return "react"
        return "node"
    return None


def is_flutter_managed_child(candidate: Path, root: Path) -> bool:
    current = candidate
    while current != root and current != current.parent:
        base = current.name
        parent = current.parent
        if base in FLUTTER_PLATFORM_DIRS and detect_project_type(parent) == "flutter":
            return True
        current = parent
    return False


def is_tauri_managed_node_child(candidate: Path, tauri_root: Path) -> bool:
    if candidate == tauri_root or tauri_root not in candidate.parents:
        return False
    config_path = tauri_root / "src-tauri" / "tauri.conf.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    build = config.get("build")
    if not isinstance(build, dict):
        return False
    frontend_dist = build.get("frontendDist")
    if isinstance(frontend_dist, str) and "://" not in frontend_dist:
        output = (config_path.parent / frontend_dist).resolve()
        if candidate == output or candidate in output.parents:
            return True
    relative = candidate.relative_to(tauri_root).as_posix()
    for key in ("beforeBuildCommand", "beforeDevCommand"):
        command = build.get(key)
        if isinstance(command, str) and relative in command:
            return True
    return False


def scan_projects(root: Path) -> List[Project]:
    root = canonical_dir(root)
    candidates = set()
    for current_text, dirs, files in os.walk(root):
        dirs[:] = [name for name in dirs if name not in EXCLUDED_DIRS]
        current = Path(current_text)
        for name in files:
            if name not in MARKER_NAMES:
                continue
            marker = current / name
            candidate = current.parent if marker.as_posix().endswith("/src-tauri/tauri.conf.json") else current
            candidates.add(candidate.resolve())
    tauri_roots = {
        candidate for candidate in candidates
        if (candidate / "src-tauri" / "tauri.conf.json").is_file()
    }
    projects = []
    for candidate in sorted(candidates, key=str):
        if is_flutter_managed_child(candidate, root):
            continue
        kind = detect_project_type(candidate)
        if kind in {"react", "next", "node"} and any(
            is_tauri_managed_node_child(candidate, tauri_root)
            for tauri_root in tauri_roots
        ):
            continue
        if kind:
            projects.append(Project(kind, candidate))
    return projects


def projects_for_root(root: Path) -> List[Project]:
    root = canonical_dir(root)
    direct = detect_project_type(root)
    return [Project(direct, root)] if direct else scan_projects(root)


def contains_gradle(directory: Path, pattern: str) -> bool:
    combined, _ = gradle_evidence(directory, 4)
    return bool(re.search(pattern, combined))


def audit_item(project: Project, category: str, check: str, status: str, detail: str) -> dict:
    return {"type": project.type, "path": str(project.path), "category": category,
            "check": check, "status": status, "detail": detail}


def audit_project(project: Project) -> List[dict]:
    kind, directory = project.type, project.path
    items: List[dict] = []
    add = lambda category, check, status, detail: items.append(
        audit_item(project, category, check, status, detail))
    if kind == "flutter":
        add("optimization", "release-build", "enforced", "선택한 모든 출력에 release 빌드와 icon tree shaking을 적용")
        add("obfuscation", "native-symbols", "enforced", "AAB/APK/IPA에 --obfuscate와 --split-debug-info 적용")
        add("obfuscation", "web", "not-supported", "Flutter web은 최적화 빌드지만 Dart --obfuscate 대상이 아님")
    elif kind == "tauri":
        cargo = read_text(directory / "src-tauri" / "Cargo.toml")
        package = read_text(directory / "package.json")
        if re.search(r"^\s*lto\s*=\s*(true|\"thin\"|\"fat\")", cargo, re.MULTILINE):
            add("optimization", "rust-lto", "configured", "Cargo release LTO 설정 감지")
        else:
            add("optimization", "rust-lto", "recommended", "Cargo.toml release profile의 lto 설정을 검토")
        if re.search(r"^\s*strip\s*=\s*(true|\"symbols\"|\"debuginfo\")", cargo, re.MULTILINE):
            add("optimization", "rust-strip", "configured", "Rust strip 설정 감지")
        else:
            add("optimization", "rust-strip", "recommended", "배포 바이너리의 strip 설정을 검토")
        if re.search(r'"(vite|next|react-scripts)"\s*:', package):
            add("optimization", "frontend-minify", "framework-default", "프런트엔드 도구의 production minify/tree-shaking에 위임")
        else:
            add("optimization", "frontend-minify", "unknown", "프런트엔드 build script의 minify 설정을 수동 확인")
        env_macos = read_text(directory / ".env.macos")
        obfuscate = os.environ.get("TAURI_OBFUSCATE_JS", "false") == "true" or bool(
            re.search(r"^TAURI_OBFUSCATE_JS\s*=\s*['\"]?true", env_macos, re.MULTILINE))
        if obfuscate:
            add("obfuscation", "frontend-js", "configured", "javascript-obfuscator 활성화 감지")
        else:
            add("obfuscation", "frontend-js", "optional-off", "기본 minify만 적용; 추가 JS 난독화는 꺼져 있음")
        add("obfuscation", "rust-native", "compiled", "Rust는 release 네이티브 바이너리로 컴파일되며 난독화와 동일 개념은 아님")
    elif kind == "android":
        configured = contains_gradle(directory, r"(isMinifyEnabled|minifyEnabled)[\s=]+true")
        add("optimization", "android-minify", "configured" if configured else "not-configured",
            "release minify/R8 활성화 감지" if configured else "release minifyEnabled/isMinifyEnabled=true를 확인하지 못함")
        configured = contains_gradle(directory, r"(isShrinkResources|shrinkResources)[\s=]+true")
        add("optimization", "resource-shrinking", "configured" if configured else "not-configured",
            "Android resource shrinking 활성화 감지" if configured else "release shrinkResources/isShrinkResources=true를 확인하지 못함")
        configured = contains_gradle(directory, r"proguardFiles|proguardFile")
        add("obfuscation", "r8-rules", "configured" if configured else "not-configured",
            "ProGuard/R8 규칙 연결 감지" if configured else "ProGuard/R8 규칙 연결을 확인하지 못함")
    elif kind in {"kotlin", "kotlin-multiplatform", "gradle"}:
        add("optimization", "gradle-release", "project-specific", "기본 build task를 실행하며 최적화 수준은 Gradle 프로젝트 설정에 따름")
        configured = contains_gradle(directory, r"proguard|r8|shadowJar|com\.github\.jengelman\.gradle\.plugins\.shadow")
        add("obfuscation", "jvm-obfuscation", "configured" if configured else "not-configured",
            "축소/난독화 관련 Gradle 설정 감지" if configured else "일반 Kotlin/JVM build는 자동 난독화를 보장하지 않음")
    elif kind in {"react", "next", "node"}:
        package = read_text(directory / "package.json")
        framework = bool(re.search(r'"(vite|next|react-scripts)"\s*:', package))
        add("optimization", "production-bundle", "framework-default" if framework else "unknown",
            "production build 도구의 minify/tree-shaking에 위임" if framework else "scripts.build가 최적화 빌드인지 수동 확인")
        configured = bool(re.search(r"javascript-obfuscator|webpack-obfuscator|rollup-plugin-obfuscator", package))
        add("obfuscation", "javascript", "configured" if configured else "not-configured",
            "JS 난독화 패키지 감지" if configured else "minification은 난독화 보장이 아니며 별도 난독화 설정을 확인하지 못함")
    return items


def project_resource_root(project: Project) -> Path:
    if project.type in {"react", "next", "node"}:
        return node_workspace_root(project.path)
    return project.path


def plan_item(project: Project, options: Options) -> dict:
    environment = os.environ.copy()
    values: Dict[str, object] = {
        "version_bump": options.version_bump,
        "jobs": options.jobs,
        "execution_group": str(project_resource_root(project)),
    }
    if project.type == "flutter":
        values.update({
            "outputs": options.flutter_outputs,
            "output_selection": "auto-platform" if options.flutter_outputs == "auto" else "explicit",
            "platform": options.flutter_platform if options.flutter_outputs == "auto" else None,
            "skip_clean": options.skip_clean,
        })
    elif project.type == "tauri":
        obfuscate = environment.get("TAURI_OBFUSCATE_JS", "") or dotenv_value(
            project.path / ".env.macos", "TAURI_OBFUSCATE_JS"
        )
        values.update({
            "package_mode": os.environ.get("UBS_TAURI_PACKAGE_MODE", "auto"),
            "skip_install": os.environ.get("UBS_SKIP_INSTALL", "false") == "true",
            "obfuscate_js": obfuscate == "true",
        })
    elif project.type in {"android", "kotlin-multiplatform", "kotlin", "gradle"}:
        gradle_arguments = resolved_gradle_arguments(project.type, project.path, environment)
        values.update({
            "gradle_task": gradle_arguments[0],
            "gradle_arguments": gradle_arguments,
            "gradle_optimize": environment.get("UBS_GRADLE_OPTIMIZE", "false") == "true",
            "gradle_flags": split_cli_arguments(environment.get("UBS_GRADLE_FLAGS", "")),
        })
    else:
        workspace = node_workspace_root(project.path)
        manager = detect_node_package_manager(project.path)
        values.update({
            "build_script": environment.get("UBS_NODE_BUILD_SCRIPT", "build"),
            "skip_install": environment.get("UBS_SKIP_INSTALL", "false") == "true",
            "install_mode": environment.get("UBS_INSTALL_MODE", "auto"),
            "package_manager": manager,
            "workspace_root": str(workspace),
            "install_command": node_install_command(workspace, manager),
        })
    return {"type": project.type, "path": str(project.path),
            "adapter": ADAPTERS[project.type], "options": values}


ARTIFACT_PATTERNS = {
    "flutter": ["build/app/outputs/bundle/release/*.aab", "build/app/outputs/flutter-apk/*.apk", "build/ios/ipa/*.ipa", "build/web"],
    "tauri": ["src-tauri/target/release/bundle/*/*", "signing/build/*.pkg"],
    "android": ["**/build/outputs/**/*.aab", "**/build/outputs/**/*.apk"],
    "kotlin-multiplatform": ["**/build/libs/*.jar", "**/build/bin/**/*"],
    "kotlin": ["**/build/libs/*.jar"],
    "gradle": ["**/build/libs/*"],
    "react": ["dist", "build"], "next": [".next"], "node": ["dist", "build"],
}
DIRECTORY_PATTERNS = {"build/web", "dist", "build", ".next", "src-tauri/target/release/bundle/*/*"}


def discover_artifacts(project: Project) -> List[str]:
    found = set()
    for pattern in ARTIFACT_PATTERNS.get(project.type, []):
        for value in glob.glob(str(project.path / pattern), recursive=True):
            path = Path(value)
            if path.is_file() or (path.is_dir() and pattern in DIRECTORY_PATTERNS):
                found.add(str(path.resolve()))
    return sorted(found)


class BuildReport:
    def __init__(self, path: Optional[Path]) -> None:
        self.path = path
        self.results: List[dict] = []
        self.lock = threading.Lock()
        if path:
            path.parent.mkdir(parents=True, exist_ok=True)
            self.write()

    def append(self, project: Project, status: int, planned: bool) -> None:
        if not self.path:
            return
        result = {
            "type": project.type,
            "project": str(project.path),
            "status": "planned" if planned else ("success" if status == 0 else "failed"),
            "exit_code": status,
            "artifacts": discover_artifacts(project) if status == 0 and not planned else [],
        }
        with self.lock:
            self.results.append(result)
            self.write()

    def write(self) -> None:
        if not self.path:
            return
        data = {"schema_version": 1, "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                "results": sorted(self.results, key=lambda item: (item["project"], item["type"]))}
        temporary = self.path.with_name(self.path.name + ".tmp")
        temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.replace(temporary, self.path)


def parse_options(argv: Sequence[str]) -> Options:
    args = list(argv)
    options = Options()
    if args and args[0] in {
        "detect", "list", "audit", "plan", "update", "build",
        "node-adapter", "gradle-adapter", "help", "-h", "--help",
    }:
        first = args.pop(0)
        options.command = "detect" if first == "list" else ("help" if first in {"help", "-h", "--help"} else first)
    index = 0
    while index < len(args):
        value = args[index]
        if options.command == "update":
            if value == "--check": options.update_check = True
            elif value == "--dry-run": options.dry_run = True
            elif value == "--json": options.json_output = True
            elif value == "--prune-backups":
                index += 1
                if index >= len(args): raise ValueError("--prune-backups 일수가 필요합니다.")
                try: options.update_prune_days = int(args[index])
                except ValueError as error: raise ValueError("보존 일수는 0 이상의 정수여야 합니다.") from error
                if options.update_prune_days < 0: raise ValueError("보존 일수는 0 이상의 정수여야 합니다.")
            elif value in {"-h", "--help"}: options.command = "help"
            else: raise ValueError(f"update에서 지원하지 않는 옵션 또는 인자입니다: {value}")
            index += 1
            continue
        if value == "--all": options.build_all = True
        elif value == "--dry-run": options.dry_run = True
        elif value == "--json": options.json_output = True
        elif value == "--non-interactive": options.non_interactive = True
        elif value == "--interactive": options.non_interactive = False
        elif value == "--skip-clean": options.skip_clean = True
        elif value == "--clean": options.skip_clean = False
        elif value == "--fail-fast": options.fail_fast = True
        elif value in {"--version-bump", "--flutter-platform", "--flutter-outputs", "--type", "--project", "--report-json", "--jobs"}:
            index += 1
            if index >= len(args): raise ValueError(f"{value} 값이 필요합니다.")
            argument = args[index]
            if value == "--version-bump": options.version_bump = argument
            elif value == "--flutter-platform": options.flutter_platform = argument
            elif value == "--flutter-outputs": options.flutter_outputs = argument
            elif value == "--type": options.type_filter = argument
            elif value == "--project": options.project_path = Path(argument)
            elif value == "--report-json": options.report_json = Path(argument).expanduser().absolute()
            else:
                try: options.jobs = int(argument)
                except ValueError as error: raise ValueError("--jobs는 1 이상의 정수여야 합니다.") from error
        elif value in {"-h", "--help"}: options.command = "help"
        elif value.startswith("--"): raise ValueError(f"알 수 없는 옵션: {value}")
        else: options.root = Path(value)
        index += 1
    return options


def validate_options(options: Options) -> None:
    if options.version_bump not in {"none", "build", "patch", "minor", "major"}:
        raise ValueError(f"잘못된 version bump: {options.version_bump}")
    if options.flutter_platform not in {"auto", "all", "ios", "android"}:
        raise ValueError(f"잘못된 Flutter 플랫폼: {options.flutter_platform}")
    if options.flutter_outputs != "auto":
        outputs = options.flutter_outputs.split(",")
        if not outputs or any(value not in {"appbundle", "apk", "ipa", "web"} for value in outputs):
            raise ValueError(f"잘못된 Flutter 출력: {options.flutter_outputs}")
    if options.jobs < 1:
        raise ValueError("--jobs는 1 이상의 정수여야 합니다.")


def selected_projects(options: Options, root: Path) -> List[Project]:
    if options.project_path:
        project_path = canonical_dir(options.project_path)
        kind = detect_project_type(project_path)
        projects = [Project(kind, project_path)] if kind else []
    elif options.build_all:
        projects = scan_projects(root)
    else:
        projects = projects_for_root(root)
    return [project for project in projects if not options.type_filter or project.type == options.type_filter]


def projects_conflict(left: Project, right: Project) -> bool:
    left_root = project_resource_root(left)
    right_root = project_resource_root(right)
    return bool(
        left_root == right_root
        or left.path in right.path.parents
        or right.path in left.path.parents
        or left_root in right_root.parents
        or right_root in left_root.parents
    )


def project_groups(projects: Sequence[Project]) -> List[List[Project]]:
    parents = list(range(len(projects)))

    def find(index: int) -> int:
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    def union(left: int, right: int) -> None:
        left_root, right_root = find(left), find(right)
        if left_root != right_root:
            parents[right_root] = left_root

    for left in range(len(projects)):
        for right in range(left + 1, len(projects)):
            if projects_conflict(projects[left], projects[right]):
                union(left, right)
    groups: Dict[int, List[Project]] = {}
    for index, project in enumerate(projects):
        groups.setdefault(find(index), []).append(project)
    return list(groups.values())


def resolved_plan_items(projects: Sequence[Project], options: Options) -> List[dict]:
    group_ids: Dict[Project, str] = {}
    for index, group in enumerate(project_groups(projects), 1):
        group_id = f"group-{index}:{group[0].path}"
        for project in group:
            group_ids[project] = group_id
    items = []
    for project in projects:
        item = plan_item(project, options)
        item["options"]["execution_group"] = group_ids[project]
        items.append(item)
    return items


def run_project(project: Project, options: Options, report: BuildReport) -> int:
    adapter_relative = ADAPTERS.get(project.type)
    if not adapter_relative:
        eprint(f"{RED}지원하지 않는 프로젝트 타입입니다: {project.type}{NC}")
        return 1
    adapter_path = adapter_relative.split("#", 1)[0]
    adapter = RUNTIME_ROOT / adapter_path
    if not adapter.is_file():
        eprint(f"{RED}빌드 어댑터가 없습니다: {adapter}{NC}")
        return 1
    print(f"{CYAN}▶ [{project.type}] {project.path}{NC}")
    if options.dry_run:
        runtime = "python3" if project.type in PYTHON_ADAPTER_TYPES else "bash"
        print(f"  (dry-run) {runtime} {adapter_relative}")
        if project.type == "flutter":
            print(f"  Flutter outputs={options.flutter_outputs} platform={options.flutter_platform} version-bump={options.version_bump}")
        report.append(project, 0, True)
        return 0
    environment = os.environ.copy()
    environment.update({
        "UBS_PROJECT_TYPE": project.type,
        "UBS_NON_INTERACTIVE": str(options.non_interactive).lower(),
        "UBS_VERSION_BUMP": options.version_bump,
        "UBS_FLUTTER_PLATFORM": options.flutter_platform,
        "UBS_FLUTTER_OUTPUTS": options.flutter_outputs,
        "UBS_SKIP_CLEAN": str(options.skip_clean).lower(),
        "UBS_RUNTIME_ROOT": str(RUNTIME_ROOT),
    })
    if project.type in PYTHON_ADAPTER_TYPES:
        status = run_python_adapter(project.type, project.path, environment)
    else:
        status = subprocess.run(["bash", str(adapter)], cwd=project.path, env=environment, check=False).returncode
    report.append(project, status, False)
    return status


def execute_projects(projects: Sequence[Project], options: Options, report: BuildReport) -> int:
    if not projects:
        eprint(f"{YELLOW}조건에 맞는 프로젝트가 없습니다.{NC}")
        return 1
    succeeded = failed = 0
    if options.jobs == 1 or len(projects) == 1 or options.fail_fast:
        if options.fail_fast and options.jobs > 1:
            print(f"{YELLOW}--fail-fast에서는 결정적 중단을 위해 순차 실행합니다.{NC}")
        for project in projects:
            status = run_project(project, options, report)
            if status == 0:
                succeeded += 1
            else:
                failed += 1
                eprint(f"{RED}✗ 빌드 실패: [{project.type}] {project.path}{NC}")
                if options.fail_fast:
                    break
    else:
        groups = project_groups(projects)
        workers = min(options.jobs, len(groups))
        serialized = sum(1 for group in groups if len(group) > 1)
        print(
            f"{CYAN}프로젝트 {len(projects)}개를 충돌 없는 {len(groups)}개 그룹으로 나눠 "
            f"최대 {workers}개씩 병렬 실행합니다 (직렬 그룹 {serialized}개).{NC}"
        )

        def run_group(group: Sequence[Project]) -> List[tuple[Project, int]]:
            return [(project, run_project(project, options, report)) for project in group]

        with ThreadPoolExecutor(max_workers=workers, thread_name_prefix="ubs-build") as executor:
            futures = {executor.submit(run_group, group): group for group in groups}
            for future in as_completed(futures):
                try:
                    results = future.result()
                except Exception as error:
                    group = futures[future]
                    eprint(f"{RED}✗ 빌드 그룹 실행 오류: {error}{NC}")
                    results = [(project, 1) for project in group]
                for project, status in results:
                    if status == 0:
                        succeeded += 1
                    else:
                        failed += 1
                        eprint(f"{RED}✗ 빌드 실패: [{project.type}] {project.path}{NC}")
    print("------------------------------------------------------------")
    print(f"전체: {succeeded + failed}  {GREEN}성공: {succeeded}{NC}  {RED}실패: {failed}{NC}")
    return 0 if failed == 0 else 1


def run_update(options: Options) -> int:
    update_lib = RUNTIME_ROOT / "scripts/lib/update.sh"
    if not update_lib.is_file():
        eprint(f"업데이트 모듈을 찾을 수 없습니다: {update_lib}")
        return 1
    environment = os.environ.copy()
    helper = RUNTIME_ROOT / ".ubs/bin" / ("ubs-helper.exe" if os.name == "nt" else "ubs-helper")
    helper_checksum = helper.with_name(helper.name + ".sha256")
    helper_parents_safe = not any(
        path.is_symlink()
        for path in (RUNTIME_ROOT / ".ubs", RUNTIME_ROOT / ".ubs/bin", helper, helper_checksum)
    )
    if helper_parents_safe and helper.is_file() and helper_checksum.is_file() and os.access(helper, os.X_OK):
        expected = read_text(helper_checksum).strip().lower()
        actual = hashlib.sha256(helper.read_bytes()).hexdigest()
        if re.fullmatch(r"[0-9a-f]{64}", expected) and actual == expected:
            environment.setdefault("UBS_RUST_HELPER", str(helper))
    if options.update_prune_days is not None:
        if options.update_check or options.dry_run:
            eprint("--prune-backups는 --check/--dry-run과 함께 사용할 수 없습니다.")
            return 2
        script = 'source "$1"; ubs_update_prune_backups "$2" "$3" "$4"'
        return subprocess.run(["bash", "-c", script, "_", str(update_lib), str(RUNTIME_ROOT),
                               str(options.update_prune_days), str(options.json_output).lower()],
                              env=environment, check=False).returncode
    script = 'source "$1"; ubs_run_update "$2" "$3" "$4"'
    command = ["bash", "-c", script, "_", str(update_lib), str(RUNTIME_ROOT),
               str(options.update_check).lower(), str(options.dry_run).lower()]
    if not options.json_output:
        return subprocess.run(command, env=environment, check=False).returncode
    result = subprocess.run(command, env=environment, text=True, stdout=subprocess.PIPE, check=False)
    mode = "check" if options.update_check else ("dry-run" if options.dry_run else "apply")
    lines = result.stdout.splitlines()
    local_version = remote_version = backup_path = None
    changed_paths = []
    for line in lines:
        version_match = re.match(r"Universal Build Script: local=(\S+) remote=(\S+)", line)
        if version_match:
            local_version, remote_version = version_match.groups()
        elif line.startswith("  - "):
            changed_paths.append(line[4:])
        elif line.startswith("백업 위치: "):
            backup_path = line.removeprefix("백업 위치: ")
    print(json.dumps({"schema_version": 1, "ok": result.returncode == 0,
                      "status": result.returncode, "mode": mode,
                      "local_version": local_version, "remote_version": remote_version,
                      "changed_paths": changed_paths, "backup_path": backup_path,
                      "output": lines}, ensure_ascii=False, indent=2))
    return result.returncode


def main(argv: Sequence[str]) -> int:
    try:
        options = parse_options(argv)
        if options.command == "help":
            print(USAGE)
            return 0
        if options.command == "update":
            return run_update(options)
        validate_options(options)
        root = canonical_dir(options.root)
        if options.command in {"node-adapter", "gradle-adapter"}:
            environment = os.environ.copy()
            if options.command == "node-adapter":
                return run_node_adapter(root, environment)
            detected = detect_project_type(root)
            kind = os.environ.get("UBS_PROJECT_TYPE", detected or "gradle")
            if kind not in {"android", "kotlin-multiplatform", "kotlin", "gradle"}:
                kind = "gradle"
            return run_gradle_adapter(kind, root, environment)
        if options.command == "detect":
            projects = projects_for_root(root)
            if options.json_output:
                print(json.dumps([{"type": item.type, "path": str(item.path)} for item in projects], ensure_ascii=False, indent=2))
            else:
                print(f"{'TYPE':<24}  PATH")
                print(f"{'-' * 24}  ----")
                for project in projects: print(f"{project.type:<24}  {project.path}")
            if not projects: eprint("감지된 프로젝트가 없습니다.")
            return 0 if projects else 1
        projects = selected_projects(options, root)
        if options.command == "audit":
            audits = [entry for project in projects for entry in audit_project(project)]
            if options.json_output: print(json.dumps(audits, ensure_ascii=False, indent=2))
            else:
                print(f"{'TYPE':<22} {'CATEGORY':<14} {'CHECK':<22} {'STATUS':<18} PATH")
                for item in audits:
                    print(f"{item['type']:<22} {item['category']:<14} {item['check']:<22} {item['status']:<18} {item['path']}")
                    print(f"  {item['detail']}")
            if not audits: eprint("감사할 프로젝트가 없습니다.")
            return 0 if audits else 1
        if options.command == "plan":
            if options.json_output:
                print(json.dumps(resolved_plan_items(projects, options), ensure_ascii=False, indent=2))
            else:
                report = BuildReport(None)
                for project in projects: run_project(project, Options(**{**options.__dict__, "dry_run": True}), report)
            if not projects: eprint("계획할 프로젝트가 없습니다.")
            return 0 if projects else 1
        if options.json_output:
            raise ValueError("--json은 detect, audit 또는 plan 명령에서 지원합니다.")
        report = BuildReport(options.report_json)
        projects = selected_projects(options, root)
        if options.project_path and not projects:
            eprint(f"{RED}프로젝트 타입을 감지할 수 없습니다: {options.project_path}{NC}")
            return 1
        if not options.project_path and not detect_project_type(root):
            print(f"{CYAN}현재 폴더는 모노레포 루트로 판단했습니다. 하위 프로젝트를 자동 빌드합니다.{NC}")
        if len(projects) == 1 and not options.build_all and options.jobs == 1:
            return run_project(projects[0], options, report)
        return execute_projects(projects, options, report)
    except (ValueError, OSError) as error:
        eprint(str(error))
        return 2 if isinstance(error, ValueError) else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
