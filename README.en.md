<div align="center">

# Universal Build Script

[한국어](README.md) · [English](README.en.md) · [日本語](README.ja.md) · [简体中文](README.zh-CN.md)

**One `./build.sh` entry point for Flutter, Tauri, Xcode iOS, Android/Kotlin/Gradle, React, Next.js, and Node — shared by humans, CI, AI agents, and MCP.**

[Quick start](#quick-start) · [Architecture](#architecture-and-flow) · [Commands](#commands) · [Security](#safe-runtime-updates) · [Troubleshooting](#troubleshooting)

</div>

## What it does

Universal Build Script decides whether the current directory is one project or a monorepo, detects buildable projects, removes nested duplicates, and dispatches each project to an ecosystem adapter.

In 3.3, Python infers Node workspace, Flutter path, Gradle composite, and explicit project dependencies, then schedules topological layers. It also owns the Xcode-only iOS adapter. A dependency-free local stdio MCP server provides root-scoped read-only tools by default.

| Concern | Default behavior |
|---|---|
| Interaction | Non-interactive and CI-safe |
| Version | Unchanged unless a bump is explicitly requested |
| Monorepo | Build detected projects in topological dependency order |
| Flutter | macOS: AAB + IPA; other hosts: AAB |
| Tauri | Native OS bundle; signed `.pkg` when macOS signing is complete |
| Failure | Continue independent projects, then return an aggregate failure |
| Runtime update | Never performed during a normal build |

## Quick start

Install into an application root or monorepo root:

```bash
curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main/install.sh | bash
```

Python 3.9 or newer is required. Rust is optional:

```bash
curl -fsSL https://raw.githubusercontent.com/kimdzhekhon/Universal-Build-Script/main/install.sh \
  | UBS_BUILD_RUST_HELPER=true bash

./scripts/build-rust-helper.sh
```

> **Upgrading from 2.x to 3.x:** run the installer once with `UBS_FORCE=true`. After 3.x is installed, `./build.sh update` manages the complete 25-file runtime bundle.

The transactional installer defaults to the immutable current release ref. `UBS_INSTALL_REF` selects another immutable ref. Key controls are `UBS_JOBS`, `UBS_INSTALL_MODE`, `UBS_MANAGE_GITIGNORE`, `UBS_GRADLE_FLAGS`, and `UBS_GRADLE_OPTIMIZE`.

Inspect first, then build:

```bash
./build.sh detect
./build.sh audit
./build.sh plan --json
./build.sh graph --json
./build.sh
```

Build selected outputs and write a machine-readable result:

```bash
./build.sh \
  --flutter-outputs appbundle,web \
  --version-bump none \
  --report-json .ubs/build-report.json
```

## Architecture and flow

```mermaid
flowchart TD
    U["Human / CI / AI / MCP"] --> B["build.sh compatibility entry point"]
    B --> D["Detect and deduplicate projects"]
    D --> P["Infer dependencies and create topological plan"]
    P --> A{"Adapter"}
    A -->|"Tauri"| T["OS bundle / signed macOS package"]
    A -->|"Flutter"| F["AAB / APK / IPA / Web"]
    A -->|"Gradle"| G["Android / Kotlin / KMP tasks"]
    A -->|"Node"| N["React / Next / Node build script"]
    A -->|"Xcode"| X["Release archive / optional IPA export"]
    T --> R["Exit status + artifact report"]
    F --> R
    G --> R
    N --> R
    X --> R
```

### Detection precedence

```mermaid
flowchart LR
    R["Directory"] --> T{"Tauri config?"}
    T -->|"yes"| TA["Register Tauri; suppress nested frontend"]
    T -->|"no"| F{"Flutter pubspec?"}
    F -->|"yes"| FL["Register Flutter; suppress platform folders"]
    F -->|"no"| X{"Xcode workspace/project?"}
    X -->|"yes"| XI["Classify Xcode-only iOS"]
    X -->|"no"| G{"Gradle settings?"}
    G -->|"yes"| GR["Classify Android / KMP / Kotlin / Gradle"]
    G -->|"no"| N{"package.json with scripts.build?"}
    N -->|"yes"| NO["Classify Next / React / Node"]
    N -->|"no"| S["Scan child directories"]
```

Precedence is **Tauri → Flutter → Xcode → Gradle → Node**. This prevents nested Tauri and Flutter platform projects from being duplicated.

### Build and report contract

```mermaid
sequenceDiagram
    participant C as Caller
    participant B as build.sh
    participant A as Adapter
    participant E as Ecosystem CLI
    participant J as JSON report
    C->>B: build --report-json report.json
    B->>B: detect, filter, validate
    loop each selected project
        B->>A: run in project directory
        A->>E: release build
        E-->>A: status and outputs
        A-->>B: exit code
        B->>J: type, project, status, artifacts
    end
    B-->>C: aggregate exit status
```

### Language and responsibility boundaries

```mermaid
flowchart TB
    E["Thin ./build.sh entry point"] --> P["Python 3: options, discovery, planning, scheduling, Node, Gradle"]
    P --> S["Bash: Flutter, Tauri, install, recovery"]
    P --> N["Node package manager"]
    P --> G["Gradle Wrapper / Gradle"]
    S --> F["Flutter CLI"]
    S --> T["Tauri/Cargo + Apple tooling"]
    P --> R["Rust: batch manifest hashing and verification"]
    P --> J["Machine-readable contract"]
    F --> A["Artifacts"]
    T --> A
    G --> A
    J --> C["AI / MCP / CI"]
    A --> C
```

The project is intentionally not shell-only. Use `--jobs N` for bounded conflict-group concurrency. Node installs default to `UBS_INSTALL_MODE=auto`, which hashes workspace package/lock/config/patch and runtime inputs; use `always` to force it. Rust batch verification avoids one helper process per managed file, with a portable fallback when the helper is absent.

### Monorepo failure policy

```mermaid
stateDiagram-v2
    [*] --> Detect
    Detect --> Select
    Select --> Build
    Build --> Success: exit 0
    Build --> Failed: non-zero
    Success --> More
    Failed --> Stop: fail-fast
    Failed --> More: default
    More --> Build: next project
    More --> Aggregate: no projects left
    Stop --> Aggregate
    Aggregate --> [*]
```

## Supported projects

| Type | Detection | Default action | Typical output |
|---|---|---|---|
| Tauri 2 | `src-tauri/tauri.conf.json` | package manager `tauri build` | native OS bundle; optional macOS `.pkg` |
| Flutter | Flutter SDK in `pubspec.yaml` | selected release outputs | AAB, split APK, IPA, Web, symbols |
| Xcode iOS | root `*.xcworkspace` or `*.xcodeproj` | Release archive; optional export | XCArchive, IPA |
| Android | Android Gradle plugin | app `bundleRelease`; otherwise `build` | project-defined Gradle outputs |
| Kotlin Multiplatform | KMP Gradle plugin | `build` | target-specific outputs |
| Kotlin/JVM or Gradle | Gradle configuration | `build` | JAR or project-defined outputs |
| Next.js / React / Node | string `scripts.build` | package manager build script | `.next`, `dist`, `build`, or project-defined |

Generated and dependency directories such as `.git`, `node_modules`, `build`, `dist`, `target`, `.gradle`, `.dart_tool`, and `.next` are excluded from recursive discovery.

## Commands

```bash
# Read-only discovery and configuration review
./build.sh detect --json /workspace
./build.sh audit --json /workspace
./build.sh plan --json /workspace
./build.sh graph --json /workspace

# Build one project or filtered monorepo projects
./build.sh build --project apps/mobile
./build.sh build --all --type flutter

# Explicit Flutter deliverables
./build.sh --flutter-outputs appbundle,apk,ipa,web

# Stop after the first project failure
./build.sh --fail-fast

# Structured build result
./build.sh --report-json .ubs/build-report.json
```

Important options:

| Option | Meaning |
|---|---|
| `--version-bump none|build|patch|minor|major` | App version policy |
| `--flutter-outputs auto|LIST` | `appbundle`, `apk`, `ipa`, and/or `web` |
| `--flutter-platform auto|all|ios|android` | Legacy platform selection when outputs are `auto` |
| `--project PATH` | Build one target plus its detected prerequisite projects |
| `--all --type TYPE` | Filter monorepo projects |
| `--clean` / `--skip-clean` | Flutter cache policy |
| `--report-json PATH` | Write per-project status and discovered artifacts |

Exit code `0` means every selected project succeeded, `1` means discovery/build failure or no matching project, and `2` means invalid arguments.

## Flutter output flow

```mermaid
flowchart TD
    S["Output selection"] --> A{"auto?"}
    A -->|"macOS"| MI["AAB + IPA"]
    A -->|"other host"| AN["AAB"]
    A -->|"explicit list"| E["Any AAB / APK / IPA / Web combination"]
    MI --> I{"IPA requested?"}
    E --> I
    I -->|"yes"| P{"Project ExportOptions.plist exists?"}
    P -->|"yes"| O["Use project policy"]
    P -->|"no"| T["Use managed generic App Store template"]
    O --> B["Release build + separated symbols"]
    T --> B
    AN --> B
```

Native Flutter outputs use release mode, obfuscation, and split debug information. Web uses release optimization and tree shaking, but native Dart obfuscation does not apply to Web.

## Tauri platform flow

```mermaid
flowchart TD
    B["tauri build"] --> O{"Host OS"}
    O -->|"Windows"| W["Project-configured MSI / NSIS bundle"]
    O -->|"Linux"| L["Project-configured deb / AppImage / rpm bundle"]
    O -->|"macOS"| M{"Package mode"}
    M -->|"unsigned"| A["Default .app"]
    M -->|"auto"| C{"All Apple signing inputs available?"}
    M -->|"signed"| V{"All Apple signing inputs available?"}
    C -->|"no"| A
    C -->|"yes"| P["codesign verification + signed .pkg"]
    V -->|"yes"| P
    V -->|"no"| E["Fail before packaging"]
```

Package manager selection uses `packageManager`, then lock files for pnpm, Yarn, Bun, and finally npm. Frozen/immutable installation is used where supported.

## Dependency graph and Xcode iOS

`./build.sh graph --json` returns `nodes`, dependency `edges`, and topological `layers`. Builds use the same layers: independent projects in one layer may run under `--jobs N`, while a failed layer blocks its dependents. UBS infers Node workspace package references, Flutter `path:` dependencies, and Gradle `includeBuild(...)`. Add relationships that cannot be inferred in `ubs.dependencies.json`:

```json
{"schema_version":1,"dependencies":{"apps/web":["packages/ui"]}}
```

Paths must remain inside the workspace; cycles are rejected. Native roots containing `*.xcworkspace` or `*.xcodeproj` are detected as `ios-xcode`. On macOS, UBS archives a shared scheme in Release mode. Set `UBS_XCODE_SCHEME` when multiple schemes are ambiguous, and set `UBS_XCODE_EXPORT=true` plus `UBS_XCODE_EXPORT_OPTIONS` to export an IPA.

## Safe runtime updates

A normal build never downloads UBS code. Update operations are explicit:

```bash
./build.sh update --check
./build.sh update --dry-run
./build.sh update
./build.sh update --check --json
./build.sh update --prune-backups 30
```

```mermaid
sequenceDiagram
    participant C as Caller
    participant U as Updater
    participant H as HTTPS source
    participant B as Backup
    participant F as Managed files
    C->>U: check / dry-run / apply
    U->>H: fetch manifest
    U->>U: validate SemVer, allowlist, duplicates, missing paths
    U->>F: compare local SHA-256
    alt check or dry-run
        U-->>C: changed paths only
    else apply
        U->>H: download every changed file
        U->>U: verify every SHA-256 before mutation
        U->>B: persist previous files
        U->>F: temporary file + rename
        alt partial failure
            B-->>F: roll back installed files
        end
        U-->>C: version and backup path
    end
```

For higher-assurance CI, pin the manifest with `UBS_UPDATE_MANIFEST_SHA256`. The updater blocks path traversal, symbolic-link destinations, concurrent writers, and downgrades unless explicitly permitted. A hash pin is not a substitute for an independent signature or transparency log.

## Privacy and secret hygiene

`.gitignore` excludes real environment files, Apple/Android signing material, service configuration, caches, and generated packages. Example files must contain placeholders only.

```bash
git status --short
git check-ignore .env .env.macos signing/App.provisionprofile build/app.aab
```

Ignore rules do not erase tracked files or commit author metadata. Rotate any exposed credential before considering history rewriting.

```mermaid
flowchart LR
    D["Developer machine"] --> E["Placeholder examples"]
    D --> S["Secrets and signing inputs"]
    D --> O["Generated artifacts"]
    E -->|"tracked"| G["Git / PR"]
    S -->|"ignored"| L["Local or secret store"]
    O -->|"ignored"| L
    G --> C["CI privacy validation"]
    S -.->|"injected at build time"| R["Build runtime"]
```

## AI and MCP

The repository includes [`skills/universal-build`](skills/universal-build/SKILL.md). An agent should follow:

```text
detect --json → audit --json → plan --json → explicit user approval → build --report-json
```

Run the bundled dependency-free stdio server with `python3 /ABSOLUTE/PATH/scripts/ubs_mcp.py` and set `UBS_MCP_ROOT` to the allowed workspace. It exposes `ubs_detect`, `ubs_audit`, `ubs_plan`, `ubs_graph`, and `ubs_update_check`. `ubs_build` is hidden unless `UBS_MCP_ALLOW_BUILD=true`; a real build also requires `confirm=true`. Paths outside the configured root and arbitrary shell fragments are rejected.

## Optimization audit boundaries

`audit` is static evidence, not release certification. It distinguishes release optimization, deliberate obfuscation, symbol separation, and signing. Verify actual outputs with ecosystem tools when high assurance is required; preserve Flutter symbols, Android mappings, native symbols, and required source maps.

## Validation

```bash
bash -n build.sh install.sh scripts/*.sh scripts/lib/*.sh tests/*.sh
python tests/test_python_core.py
python tests/test_mcp.py
bash tests/test-detection.sh
bash tests/test-install.sh
bash tests/test-python-adapters.sh
bash tests/test-update.sh
bash tests/test-rust-helper.sh
scripts/generate-update-manifest.sh > /tmp/update-manifest.txt
diff -u scripts/update-manifest.txt /tmp/update-manifest.txt
```

Tests use temporary fixtures and mocked ecosystem commands. Real SDK builds, Apple/Android signing, and artifact-level reverse engineering remain project-specific validation steps.

## Troubleshooting

- Not detected: confirm the framework marker and run `./build.sh detect`.
- macOS auto mode unexpectedly builds iOS: use `--flutter-platform android` or explicit outputs.
- Android flavor: set `UBS_GRADLE_TASK=:app:bundleProdRelease`.
- Tauri creates `.app` instead of `.pkg`: run with `UBS_TAURI_PACKAGE_MODE=signed` to expose missing signing inputs.
- Wrong package manager: align `packageManager` and the committed lock file.

## Known limitations

- Builds are sequential by default. `--jobs N` runs non-overlapping projects within each topological layer; shared Node workspaces and overlapping paths stay serialized.
- Automatic dependency inference covers Node package names, Flutter paths, and Gradle composites. Generated-code or custom-task relationships need `ubs.dependencies.json`.
- Ambiguous Xcode schemes require `UBS_XCODE_SCHEME`.
- Gradle flavors, custom release tasks, and KMP deployment tasks may require overrides.
- Tauri JS obfuscation assumes a `dist/` frontend output.
- Artifact reporting searches known default output locations.
- The update manifest supports external hash pinning but not an independent signature/transparency log.

## License

MIT License — Copyright © 2024–2026 kimdzhekhon. See [LICENSE](LICENSE).
