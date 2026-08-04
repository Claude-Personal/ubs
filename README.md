# ubs

**Universal release build orchestrator for Flutter, Tauri, Android/Kotlin, React/Node, and iOS/Xcode — one command, auto-detected, AI-agent and MCP ready.**

`ubs` (entry point `./build.sh`) is a Bash + Python CLI that detects what kind of project — or monorepo of projects — you're standing in, resolves inter-project build dependencies into a topological order, and runs the right platform-specific build adapter. It ships with safe interactive defaults, a non-interactive/CI mode, parallel builds of independent projects, an optimization/obfuscation audit, App Store Connect and Google Play publishing, a signed and atomic self-update mechanism, and CLI output localized into `ko`/`en`/`ja`/`zh`. A bundled MCP server exposes the same detect/audit/plan/graph/build surface to AI agents.

This document is grounded entirely in the current `build.sh`, `install.sh`, `scripts/`, and `native/ubs-helper/` of this repository — no invented commands, flags, or architecture.

## Table of contents

- [What it does](#what-it-does)
- [Pipeline overview](#pipeline-overview)
- [Architecture](#architecture)
- [CLI reference](#cli-reference)
- [Detected project types & adapters](#detected-project-types--adapters)
- [Parallel builds & dependency graph](#parallel-builds--dependency-graph)
- [Audit: optimization & obfuscation checks](#audit-optimization--obfuscation-checks)
- [Publishing](#publishing)
- [Self-update: signed and atomic](#self-update-signed-and-atomic)
- [Security: trust roots and verified install](#security-trust-roots-and-verified-install)
- [MCP server](#mcp-server)
- [Localization](#localization)
- [Requirements & install](#requirements--install)
- [License](#license)

## What it does

Given a project directory (or a monorepo root), `ubs`:

1. **Detects** every buildable sub-project by inspecting the filesystem — no config file required — and classifies each into one of ten supported types.
2. **Resolves dependencies** between detected projects (via inferred Node workspace/package-name links, or an explicit `ubs.dependencies.json`) into topologically ordered layers.
3. **Plans** the exact build command for each project — read-only, so it's safe to inspect before anything runs.
4. **Builds** each project through its adapter, in parallel across independent projects when `--jobs N > 1`, with a safe interactive version-bump/platform prompt on a real terminal and deterministic non-interactive defaults everywhere else (CI, MCP, `UBS_NON_INTERACTIVE=true`).
5. **Audits** every project's optimization and obfuscation configuration against platform-specific checks, independent of running an actual build.
6. **Publishes** finished artifacts to App Store Connect (`.ipa`/`.pkg`) or Google Play (`.aab`) on request.
7. **Updates** its own managed files in place — signature-verified, staged, and atomically applied with automatic rollback on any failure.

## Pipeline overview

```mermaid
flowchart TB
    Root["project root or monorepo root"] --> Detect["ubs.py: detect_projects\n(scripts/lib/detect.sh signals)"]
    Detect --> Graph["build_project_graph\ninferred deps + ubs.dependencies.json"]
    Graph --> Topo["topological_layers"]
    Topo --> Plan["resolved_plan_items\n(read-only)"]
    Plan -->|"./build.sh"| Execute["execute_projects"]
    Execute -->|"jobs == 1"| Seq["sequential run_project"]
    Execute -->|"jobs > 1"| Par["ThreadPoolExecutor per layer\nconflict-free groups"]
    Seq --> Adapter{"adapter for project.type"}
    Par --> Adapter
    Adapter -->|"tauri"| BTauri["scripts/build-tauri.sh\n-> build-tauri-macos.sh"]
    Adapter -->|"flutter"| BFlutter["scripts/build-flutter.sh"]
    Adapter -->|"android/kotlin*/gradle"| BGradle["ubs.py#gradle\nrun_gradle_adapter"]
    Adapter -->|"react/next/node"| BNode["ubs.py#node\nrun_node_adapter"]
    Adapter -->|"ios-xcode"| BXcode["ubs.py#xcode\nrun_xcode_adapter"]
    BTauri --> Report["BuildReport\n+ artifact_output_directories"]
    BFlutter --> Report
    BGradle --> Report
    BNode --> Report
    BXcode --> Report
    Report -->|"--publish or prompted"| Publish["publish_projects\nApp Store Connect / Google Play"]
```

## Architecture

```mermaid
flowchart TD
    entry["build.sh\nstable Bash entry point"]
    core["scripts/ubs.py\nCLI parsing, detection, graph,\nplanning, orchestration, reports"]
    detect["scripts/lib/detect.sh\nfilesystem-signal type detection"]
    audit["scripts/lib/audit.sh"]
    update["scripts/lib/update.sh\nsigned manifest fetch/verify/apply"]
    i18nsh["scripts/lib/i18n.sh + i18n_messages.sh\nbash message catalog"]
    i18npy["scripts/i18n.py + i18n_messages.py\npython message catalog"]
    npm["scripts/lib/node-package-manager.sh"]
    tauri["scripts/build-tauri.sh -> build-tauri-macos.sh"]
    flutter["scripts/build-flutter.sh"]
    rustbin["native/ubs-helper\nRust: sha256 + manifest batch verify"]
    mcp["scripts/ubs_mcp.py\nstdio MCP server"]
    installer["install.sh\ncurl\\|bash transactional installer"]

    entry --> core
    entry -.->|"core missing"| bootstrap["scripts/bootstrap-update.sh\nself-heal via update.sh"]
    core --> detect
    core --> update
    core --> i18npy
    core --> tauri
    core --> flutter
    update --> rustbin
    update --> i18nsh
    tauri --> npm
    mcp --> core
    installer --> update
```

| File | Role |
|---|---|
| `build.sh` | Stable compatibility entry point; execs `scripts/ubs.py`, or delegates to `bootstrap-update.sh` when the Python core is missing |
| `install.sh` | Standalone (`curl \| bash`) transactional installer — stages every managed file, verifies checksums against a signed manifest, then atomically replaces, with full rollback on any failure |
| `scripts/ubs.py` | The orchestration core: argument parsing, project detection dispatch, dependency graph, topological + parallel execution, audit, publish (App Store Connect / Google Play), JSON output for `detect`/`audit`/`plan`/`graph` |
| `scripts/lib/detect.sh` | Pure filesystem signals (`pubspec.yaml`, `src-tauri/tauri.conf.json`, `build.gradle*`, `package.json`, `*.xcodeproj`, …) that classify a directory into one of the ten supported types |
| `scripts/lib/audit.sh` | Optimization/obfuscation policy checks, called by `ubs.py`'s `audit_project` |
| `scripts/lib/update.sh` | Fetches the signed update manifest, verifies its ECDSA-P256 signature, downloads and hashes each managed file, stages, backs up, and atomically replaces — with `ubs_update_allowed_path` as a second, independent allow-list beyond the manifest's own signature |
| `scripts/bootstrap-update.sh` | Minimal recovery path used only when `scripts/ubs.py` itself is missing |
| `scripts/build-tauri.sh` / `build-tauri-macos.sh` | Tauri adapter: version bump, frontend build, optional JS obfuscation, `tauri build`, Apple codesigning/notarization-ready `.pkg` |
| `scripts/build-flutter.sh` | Flutter adapter: version bump, platform selection (iOS/Android/both), parallel or sequential native builds, AAB/APK/IPA/Web outputs |
| `scripts/lib/node-package-manager.sh` | Detects and drives npm/pnpm/yarn from `packageManager` + lockfile |
| `scripts/ubs_mcp.py` | Dependency-free stdio MCP server wrapping the same core |
| `native/ubs-helper` | Optional Rust binary: SHA-256 hashing and batch manifest verification, with a portable Python fallback when it isn't built |
| `scripts/lib/i18n.sh` + `i18n_messages.sh` / `scripts/i18n.py` + `i18n_messages.py` | Independent bash and Python message catalogs behind `UBS_LANG` |

## CLI reference

```text
./build.sh                         Auto-detect + unattended build with safe defaults
./build.sh detect [path]           Discover sub-projects
./build.sh detect --json [path]    Detection result as JSON for AI/MCP
./build.sh audit [path]            Audit optimization/obfuscation settings
./build.sh audit --json [path]     Audit result as JSON for AI/MCP
./build.sh plan [path]             Read-only build plan
./build.sh plan --json [path]      Build plan as JSON for AI/MCP
./build.sh graph --json [path]     Project dependency/topological-order JSON
./build.sh update --check [--json] Check for a full runtime update
./build.sh update --dry-run        Preview changed files
./build.sh update                  Safe update with verification and backup
./build.sh update --prune-backups 30  Delete update backups older than 30 days
./build.sh --dry-run               Preview which build would run
./build.sh --interactive           Choose version and platform directly
./build.sh build --project <path>  Build a specific project
./build.sh build --all --type TYPE Build only a given type
./build.sh publish [--project PATH] [--track TRACK]  Upload an existing store artifact
```

| Option | Values | Purpose |
|---|---|---|
| `--version-bump` | `none\|build\|patch\|minor\|major` | Non-interactive version-bump policy |
| `--flutter-platform` | `auto\|all\|ios\|android` | Non-interactive Flutter platform selection |
| `--flutter-outputs` | `auto\|appbundle,apk,ipa,web` (comma list) | Explicit Flutter output set |
| `--clean` / `--skip-clean` | flag | Force or skip pre-build cleaning |
| `--obfuscate-js` / `--no-obfuscate-js` | flag | Tauri frontend JS obfuscation (asked once, remembered per-repo on the first Tauri build) |
| `--publish` / `--no-publish` | flag | Force or disable store upload after a successful build |
| `--fail-fast` | flag | Stop at the first failure instead of continuing independent projects |
| `--jobs N` | integer | Parallel build limit across independent projects |
| `--report-json <file>` | path | Write the actual (not planned) build result as JSON |
| `--track` | Google Play track | `internal\|alpha\|beta\|production` for `publish` |

```bash
# Auto-detect everything under the current directory and build with safe defaults
./build.sh

# See what would run, without building anything
./build.sh --dry-run --all

# CI: non-interactive patch bump, parallel build, machine-readable report
UBS_NON_INTERACTIVE=true ./build.sh --all --version-bump patch --jobs 4 --report-json report.json

# Inspect without side effects
./build.sh detect --json
./build.sh audit --json
./build.sh graph --json
```

## Detected project types & adapters

| Type | Detection signal (`scripts/lib/detect.sh`) | Adapter |
|---|---|---|
| `tauri` | `src-tauri/tauri.conf.json` | `scripts/build-tauri.sh` → `build-tauri-macos.sh` |
| `flutter` | `pubspec.yaml` with a `flutter:` / `sdk: flutter` entry | `scripts/build-flutter.sh` |
| `android` | Gradle project targeting an Android plugin | `ubs.py#gradle` |
| `kotlin-multiplatform` | Gradle project with a KMP plugin | `ubs.py#gradle` |
| `kotlin` | Gradle project, Kotlin, no Android/KMP plugin | `ubs.py#gradle` |
| `gradle` | `build.gradle`/`build.gradle.kts`/`gradlew` without a more specific match | `ubs.py#gradle` |
| `react` | `package.json` with a React dependency | `ubs.py#node` |
| `next` | `package.json` with a Next.js dependency | `ubs.py#node` |
| `node` | `package.json` with a `build` script, no more specific framework | `ubs.py#node` |
| `ios-xcode` | `*.xcodeproj` with no Flutter/Tauri wrapper | `ubs.py#xcode` |

## Parallel builds & dependency graph

`ubs.py` infers dependencies from Node workspace membership and matching `package.json` `name`/dependency fields, then layers them with a standard topological sort. An explicit `ubs.dependencies.json` (`{"schema_version": 1, "dependencies": {"appA": ["libB"]}}`) can declare additional edges; every referenced path must resolve to a project that was actually selected, and cycles are rejected before any build starts. `./build.sh graph --json` prints the resolved layers and edges without building anything; `--jobs N` bounds how many projects in a conflict-free group run at once via a `ThreadPoolExecutor`, one layer at a time.

## Audit: optimization & obfuscation checks

`./build.sh audit` runs `audit_project` against every detected project without building it, reporting a category (`optimization`/`obfuscation`), a check name, a status (`configured`/`not-configured`/`enforced`/`project-specific`/…), and a human-readable detail — for example, Flutter's `--obfuscate`/`--split-debug-info` enforcement, Tauri's Cargo `lto`/`strip` profile and optional `javascript-obfuscator` pass, Android's R8/ProGuard and resource-shrinking flags, and Xcode's Release optimization level and installed-product symbol strip. `--json` emits the same data as structured records for CI gating or an AI agent.

## Publishing

`./build.sh publish` uploads an already-built artifact: `.ipa`/`.pkg` via `xcrun altool` to App Store Connect (needs `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `ASC_APPLE_ID`, `ASC_BUNDLE_ID`, plus a resolvable app version), or `.aab` to Google Play (needs `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `GOOGLE_PLAY_PACKAGE_NAME`, uploaded in resumable chunks via a hand-rolled service-account JWT — no Google client library dependency) at `--track internal|alpha|beta|production`. A successful `./build.sh` can also prompt to publish immediately, or do so automatically with `--publish`.

## Self-update: signed and atomic

```mermaid
sequenceDiagram
    actor Dev
    participant CLI as build.sh / ubs.py
    participant Update as lib/update.sh
    participant Remote as signed manifest host
    participant Helper as native/ubs-helper

    Dev->>CLI: ./build.sh update
    CLI->>Update: ubs_run_update(root, check, dry_run)
    Update->>Remote: fetch update-manifest.txt + .sig
    Update->>Update: verify ECDSA-P256 signature\n(embedded public key)
    Update->>Remote: fetch each managed file
    Update->>Helper: sha256 / batch-verify\n(falls back to portable hash if absent)
    Helper-->>Update: per-file hash match
    Update->>Update: reject any path outside\nthe signed, allow-listed set
    Update->>Update: back up current files
    Update->>Update: atomic replace, one file at a time
    alt any step fails
        Update->>Update: restore every applied file\nfrom the backup
    end
    Update-->>Dev: "Update complete: <version>"\n+ backup location
```

The manifest itself is generated (`scripts/generate-update-manifest.sh`) and signed (`scripts/sign-update-manifest.sh`) with a private key that never enters this repository — only the matching public key is embedded, identically, in both `install.sh` and `scripts/lib/update.sh` (CI checks the two copies match). A downgrade is refused unless `UBS_UPDATE_ALLOW_DOWNGRADE=true` is set explicitly.

## Security: trust roots and verified install

**The first install and later updates don't share a trust root.** A first-time `curl | bash` install pulls `install.sh`, the public key, the manifest, and every payload file from the same GitHub channel — so that channel is the entire trust root, and if the repository/account were ever compromised, the signature-verification code and key could be replaced together. Once installed, though, `./build.sh update` checks new manifests against the public key already on local disk (fixed at install time), so a later repository compromise can't forge a manifest that passes — the signature only protects the supply chain *after* installation.

To close that first-install gap, verify [GitHub Artifact Attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds) — Sigstore-based, signed via GitHub Actions OIDC, recorded in the public Rekor transparency log — before running the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Claude-Personal/ubs/main/install.sh -o install.sh
gh attestation verify install.sh --owner Claude-Personal   # built into gh CLI 2.49+, no cosign needed
bash install.sh
```

This confirms `install.sh` was built by this repository's own GitHub Actions workflow at tag-release time (`.github/workflows/attest-release.yml` creates one attestation per tag), moving the trust root from "whoever can push to this repo" to "GitHub's OIDC issuer (Fulcio)" — a repo/account compromise alone can no longer produce a passing attestation. As a lighter-weight, out-of-band fallback, the manifest signing public key's fingerprint is pinned below; `install.sh` also prints this value at run time, so compare it before trusting a fresh install:

```text
MANIFEST_PUBLIC_KEY fingerprint (SHA-256):
5600ca18df518517fa44ff96673ef7fbdbe7d27b8168228d32d75fc7fbae4064
```

## MCP server

`scripts/ubs_mcp.py` is a dependency-free stdio MCP server over the same core. Read-only tools are exposed by default; a real build additionally requires `UBS_MCP_ALLOW_BUILD=true` on the server and `confirm=true` on the call.

| Tool | Purpose |
|---|---|
| `ubs_detect` | Detect projects without changing anything |
| `ubs_audit` | Run the optimization/obfuscation audit |
| `ubs_plan` | Return the resolved, read-only build plan |
| `ubs_graph` | Return the dependency graph and topological layers |
| `ubs_update_check` | Check for a runtime update without modifying files |
| `ubs_build` | Run a dry-run, or an explicitly confirmed real build |

`UBS_MCP_ROOT` bounds the workspace the server can see; it defaults to the server's own working directory.

## Localization

CLI output (errors, progress, interactive menus, `--help`) resolves through `UBS_LANG`, falling back to `LC_ALL` → `LC_MESSAGES` → `LANG`, then `en`. Supported: `ko`, `en`, `ja`, `zh`.

```bash
UBS_LANG=ja ./build.sh detect
```

## Requirements & install

- Python 3.9+ (required); a Rust toolchain is optional, only for building `native/ubs-helper` locally.

```bash
curl -fsSL https://raw.githubusercontent.com/Claude-Personal/ubs/main/install.sh | bash
```

The installer defaults to the current release's immutable Git ref. `UBS_INSTALL_REF`, `UBS_JOBS`, `UBS_INSTALL_MODE`, `UBS_MANAGE_GITIGNORE`, `UBS_GRADLE_FLAGS`, and `UBS_GRADLE_OPTIMIZE` are configurable at install time.

## License

See [`LICENSE`](LICENSE).
