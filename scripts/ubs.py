#!/usr/bin/env python3
"""Universal Build Script orchestration core.

Bash remains the stable entry point and ecosystem adapters remain intentionally
small shell programs. This module owns structured parsing, discovery, audits,
planning, process orchestration, JSON output, and build reports.
"""

from __future__ import annotations

import datetime as dt
import glob
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence


RUNTIME_ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {
    ".git", "node_modules", "build", "dist", "target", ".gradle",
    ".dart_tool", ".next", ".ubs",
}
FLUTTER_PLATFORM_DIRS = {"android", "ios", "macos", "linux", "windows", "web"}
GRADLE_NAMES = {"build.gradle", "build.gradle.kts"}
MARKER_NAMES = {
    "pubspec.yaml", "tauri.conf.json", "settings.gradle",
    "settings.gradle.kts", "package.json",
}
ADAPTERS = {
    "tauri": "scripts/build-tauri.sh",
    "flutter": "scripts/build-flutter.sh",
    "android": "scripts/build-gradle.sh",
    "kotlin-multiplatform": "scripts/build-gradle.sh",
    "kotlin": "scripts/build-gradle.sh",
    "gradle": "scripts/build-gradle.sh",
    "react": "scripts/build-node.sh",
    "next": "scripts/build-node.sh",
    "node": "scripts/build-node.sh",
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


def gradle_files(directory: Path, max_depth: int = 3) -> List[Path]:
    files: List[Path] = []
    base_depth = len(directory.parts)
    for root, dirs, names in os.walk(directory):
        current = Path(root)
        depth = len(current.parts) - base_depth
        dirs[:] = [] if depth >= max_depth else [name for name in dirs if name not in EXCLUDED_DIRS]
        files.extend(current / name for name in names if name in GRADLE_NAMES)
    return files


def detect_gradle_type(directory: Path) -> Optional[str]:
    texts = [read_text(path) for path in gradle_files(directory)]
    if not texts:
        return None
    combined = "\n".join(texts)
    if re.search(r"com\.android\.(application|library)", combined):
        return "android"
    if re.search(r"multiplatform|org\.jetbrains\.kotlin\.multiplatform", combined):
        return "kotlin-multiplatform"
    if re.search(r"org\.jetbrains\.kotlin|kotlin.*(jvm|android)", combined):
        return "kotlin"
    return "gradle"


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
    projects = []
    for candidate in sorted(candidates, key=str):
        if is_flutter_managed_child(candidate, root):
            continue
        kind = detect_project_type(candidate)
        if kind:
            projects.append(Project(kind, candidate))
    return projects


def projects_for_root(root: Path) -> List[Project]:
    root = canonical_dir(root)
    direct = detect_project_type(root)
    return [Project(direct, root)] if direct else scan_projects(root)


def contains_gradle(directory: Path, pattern: str) -> bool:
    regex = re.compile(pattern)
    return any(regex.search(read_text(path)) for path in gradle_files(directory, 4))


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


def plan_item(project: Project, options: Options) -> dict:
    values: Dict[str, object] = {"version_bump": options.version_bump}
    if project.type == "flutter":
        values.update({
            "outputs": options.flutter_outputs,
            "output_selection": "auto-platform" if options.flutter_outputs == "auto" else "explicit",
            "platform": options.flutter_platform if options.flutter_outputs == "auto" else None,
            "skip_clean": options.skip_clean,
        })
    elif project.type == "tauri":
        values.update({
            "package_mode": os.environ.get("UBS_TAURI_PACKAGE_MODE", "auto"),
            "skip_install": os.environ.get("UBS_SKIP_INSTALL", "false") == "true",
            "obfuscate_js": os.environ.get("TAURI_OBFUSCATE_JS", "false") == "true",
        })
    elif project.type in {"android", "kotlin-multiplatform", "kotlin", "gradle"}:
        values["gradle_task"] = os.environ.get("UBS_GRADLE_TASK", "") or "auto"
    else:
        values.update({
            "build_script": os.environ.get("UBS_NODE_BUILD_SCRIPT", "build"),
            "skip_install": os.environ.get("UBS_SKIP_INSTALL", "false") == "true",
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
        if path:
            path.parent.mkdir(parents=True, exist_ok=True)
            self.write()

    def append(self, project: Project, status: int, planned: bool) -> None:
        if not self.path:
            return
        self.results.append({
            "type": project.type,
            "project": str(project.path),
            "status": "planned" if planned else ("success" if status == 0 else "failed"),
            "exit_code": status,
            "artifacts": discover_artifacts(project) if status == 0 and not planned else [],
        })
        self.write()

    def write(self) -> None:
        if not self.path:
            return
        data = {"schema_version": 1, "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(), "results": self.results}
        temporary = self.path.with_name(self.path.name + ".tmp")
        temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.replace(temporary, self.path)


def parse_options(argv: Sequence[str]) -> Options:
    args = list(argv)
    options = Options()
    if args and args[0] in {"detect", "list", "audit", "plan", "update", "build", "help", "-h", "--help"}:
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
        elif value in {"--version-bump", "--flutter-platform", "--flutter-outputs", "--type", "--project", "--report-json"}:
            index += 1
            if index >= len(args): raise ValueError(f"{value} 값이 필요합니다.")
            argument = args[index]
            if value == "--version-bump": options.version_bump = argument
            elif value == "--flutter-platform": options.flutter_platform = argument
            elif value == "--flutter-outputs": options.flutter_outputs = argument
            elif value == "--type": options.type_filter = argument
            elif value == "--project": options.project_path = Path(argument)
            else: options.report_json = Path(argument).expanduser().absolute()
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


def selected_projects(options: Options, root: Path) -> List[Project]:
    projects = projects_for_root(root)
    return [project for project in projects if not options.type_filter or project.type == options.type_filter]


def run_project(project: Project, options: Options, report: BuildReport) -> int:
    adapter_relative = ADAPTERS.get(project.type)
    if not adapter_relative:
        eprint(f"{RED}지원하지 않는 프로젝트 타입입니다: {project.type}{NC}")
        return 1
    adapter = RUNTIME_ROOT / adapter_relative
    if not adapter.is_file():
        eprint(f"{RED}빌드 어댑터가 없습니다: {adapter}{NC}")
        return 1
    print(f"{CYAN}▶ [{project.type}] {project.path}{NC}")
    if options.dry_run:
        print(f"  (dry-run) bash {adapter}")
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
    status = subprocess.run(["bash", str(adapter)], cwd=project.path, env=environment, check=False).returncode
    report.append(project, status, False)
    return status


def run_update(options: Options) -> int:
    update_lib = RUNTIME_ROOT / "scripts/lib/update.sh"
    if not update_lib.is_file():
        eprint(f"업데이트 모듈을 찾을 수 없습니다: {update_lib}")
        return 1
    environment = os.environ.copy()
    helper = RUNTIME_ROOT / ".ubs/bin/ubs-helper"
    if helper.is_file() and os.access(helper, os.X_OK):
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
    print(json.dumps({"ok": result.returncode == 0, "status": result.returncode,
                      "mode": mode, "output": result.stdout.splitlines()}, ensure_ascii=False, indent=2))
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
        plan_root = canonical_dir(options.project_path) if options.project_path else root
        projects = selected_projects(options, plan_root)
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
                print(json.dumps([plan_item(project, options) for project in projects], ensure_ascii=False, indent=2))
            else:
                report = BuildReport(None)
                for project in projects: run_project(project, Options(**{**options.__dict__, "dry_run": True}), report)
            if not projects: eprint("계획할 프로젝트가 없습니다.")
            return 0 if projects else 1
        if options.json_output:
            raise ValueError("--json은 detect, audit 또는 plan 명령에서 지원합니다.")
        report = BuildReport(options.report_json)
        if options.project_path:
            project_path = canonical_dir(options.project_path)
            kind = detect_project_type(project_path)
            if not kind:
                eprint(f"{RED}프로젝트 타입을 감지할 수 없습니다: {project_path}{NC}")
                return 1
            return run_project(Project(kind, project_path), options, report)
        direct = detect_project_type(root)
        if direct and not options.build_all:
            return run_project(Project(direct, root), options, report)
        if not direct:
            print(f"{CYAN}현재 폴더는 모노레포 루트로 판단했습니다. 하위 프로젝트를 자동 빌드합니다.{NC}")
        projects = [project for project in scan_projects(root)
                    if not options.type_filter or project.type == options.type_filter]
        succeeded = failed = 0
        for project in projects:
            if run_project(project, options, report) == 0: succeeded += 1
            else:
                failed += 1
                eprint(f"{RED}✗ 빌드 실패: [{project.type}] {project.path}{NC}")
                if options.fail_fast: break
        if not projects:
            eprint(f"{YELLOW}조건에 맞는 프로젝트가 없습니다.{NC}")
            return 1
        print("------------------------------------------------------------")
        print(f"전체: {succeeded + failed}  {GREEN}성공: {succeeded}{NC}  {RED}실패: {failed}{NC}")
        return 0 if failed == 0 else 1
    except (ValueError, OSError) as error:
        eprint(str(error))
        return 2 if isinstance(error, ValueError) else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
