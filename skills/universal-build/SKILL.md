---
name: universal-build
description: Detect, audit, plan, update, and run release builds across Flutter, Tauri, Android, Kotlin, Gradle, React, Next.js, and Node workspaces that contain the Universal Build Script. Use when an AI agent must inspect buildable projects, assess optimization or obfuscation coverage, select release outputs, check or apply managed runtime updates, dry-run a monorepo build, or execute ./build.sh safely.
---

# Universal Build

Use the repository's `build.sh` as the single source of truth. It is a stable Bash entry point backed by the Python orchestration core; do not invoke `scripts/ubs.py` directly or reimplement ecosystem detection inside the agent. Treat its JSON output as the machine contract. The optional Rust helper is an updater optimization, not a prerequisite for normal builds.

## Locate the Build Root

Find the nearest workspace directory containing both `build.sh` and `scripts/ubs.py`. Run all commands from that directory. If those files are absent, explain that the Universal Build Script is not installed instead of guessing build commands. `scripts/lib/detect.sh` and `scripts/lib/audit.sh` are retained only for legacy compatibility and regression tests.

## Follow the Safe Workflow

1. Inspect without mutation:

   ```bash
   ./build.sh detect --json .
   ./build.sh audit --json .
   ./build.sh plan --json .
   ```

2. Summarize detected projects, planned adapters, requested artifacts, and audit gaps. Read [references/optimization.md](references/optimization.md) before interpreting optimization or obfuscation results.
3. Run a real build only when the user requested a build or release. Keep versions unchanged unless the user explicitly requested a bump:

   ```bash
   UBS_NO_NOTIFY=true ./build.sh --version-bump none --report-json .ubs/build-report.json .
   ```

4. Read the generated build report and report successes, failures, and artifact paths. Preserve full failing command output when diagnosing.

Do not silently add signing, publishing, notarization, upload, or deployment. A signed Tauri package requires the repository's signing configuration; report missing prerequisites rather than fabricating them.

## Update the Managed Runtime

Keep updates separate from builds. Never update merely because the user requested a build. When the user asks to update Universal Build, inspect first:

```bash
./build.sh update --check
./build.sh update --dry-run
./build.sh update --check --json
```

Summarize the local and remote versions, changed managed files, and backup behavior. Run `./build.sh update` only after explicit user authorization. Do not override project source, environment files, signing material, or a project's generated `ios/ExportOptions.plist`. Report the `.ubs/backups/` path after a successful update. Prune backups only when the user requests a retention policy, for example `./build.sh update --prune-backups 30`.

## Select Outputs

Use an explicit Flutter output list when the requested deliverables are known:

```bash
./build.sh --flutter-outputs appbundle,apk,ipa,web --version-bump none .
```

Available values are `appbundle`, `apk`, `ipa`, and `web`. An explicit list overrides platform auto-selection. Use `--flutter-platform auto|all|ios|android` only with the default `--flutter-outputs auto` behavior.

Use environment overrides for non-Flutter adapters only when the project requires them:

```bash
UBS_GRADLE_TASK=assembleRelease ./build.sh .
UBS_NODE_BUILD_SCRIPT=build:production ./build.sh .
UBS_TAURI_PACKAGE_MODE=signed ./build.sh .
```

Prefer `--project PATH` for one detected project and `--all --type TYPE` for filtered monorepo builds. Use `--fail-fast` only when later independent projects should not continue after a failure.

## Interpret Claims Carefully

Treat `audit` as a static configuration review, not binary analysis. Never claim that every artifact is obfuscated merely because a production or minified build ran. Distinguish these concepts:

- optimization: release compilation, minification, tree shaking, resource shrinking, LTO, or stripping;
- obfuscation: deliberate transformation of names or control structure;
- symbol separation: debug information is stored separately and must be retained for crash symbolication;
- signing: proves publisher identity and integrity but does not optimize or obfuscate.

Verify actual artifacts and logs after a real build. For high-assurance release review, recommend ecosystem-specific artifact inspection in addition to this static audit.

## MCP Integration Contract

Expose the existing commands through a thin MCP server instead of duplicating logic:

- `detect_projects(root)` → `./build.sh detect --json ROOT`
- `audit_build(root)` → `./build.sh audit --json ROOT`
- `plan_build(root, options)` → `./build.sh plan --json ... ROOT`
- `run_build(root, options)` → `./build.sh --report-json REPORT ... ROOT`

Keep `run_build` visibly mutating and require explicit user intent. Validate option values, restrict `root` to allowed workspaces, stream stderr separately, return process exit codes, and apply execution timeouts. Do not expose arbitrary shell fragments as MCP arguments.
